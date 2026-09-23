# MiniShop — Project Spec

Extends the existing `store/` app (auth, Product CRUD, subscribers) into a small
working e-commerce JSON API. Built in 10 small, independently-shippable
features — build them in order, each one unlocks the next.

## API conventions (apply to every feature below)
- All endpoints live under `/api/v1/...`, return JSON.
- Auth: `Authorization: Bearer <token>` header (built in Feature 1).
- Errors: `{ "error": "message" }` for single errors, `{ "errors": { "field": ["msg"] } }` for validation errors (422).
- Money stored/returned in `_cents` (integers) to avoid float rounding bugs.
- Standard status codes: 200 read/update, 201 create, 204 delete, 401 not authenticated, 403 not authorized, 404 not found, 422 validation.

---

## Feature 1 — API Authentication (token-based)
**Status:** ✅ Partially implemented — an admin-only variant exists today as
`POST /api/v1/admin/login` / `GET /api/v1/admin/me`
(`app/controllers/api/v1/admin/sessions_controller.rb`), issuing the same
`api_token` this spec describes. The generic `/api/v1/login` and
`/api/v1/logout` for regular (non-admin) users are still open — build those
before Feature 10, since customers need a token too to open the chat socket.

**Goal:** let interns hit the API from Postman/curl without a browser session cookie.

**Tasks**
- [x] Add `api_token` to `User` via `has_secure_token :api_token`
- [x] `Api::V1::SessionsController#create` (`POST /api/v1/login`) authenticates email/password, returns token
- [x] `Api::V1::BaseController` with `before_action :authenticate_api_user!` — reads header, loads user by token
- [x] `GET /api/v1/me` returns the current user (sanity-check endpoint)
- [x] `POST /api/v1/logout` regenerates the token (invalidates the old one)

**Acceptance criteria**
- Valid credentials → 200 `{ token, user: { id, email, role } }`
- Invalid credentials → 401 `{ error: "Invalid email or password" }`
- Any protected endpoint without/with a bad `Authorization` header → 401
- `GET /api/v1/me` with a valid token → 200 with the user's own data

**Endpoints**

| Method | Path | Body | Response |
|---|---|---|---|
| POST | /api/v1/login | `{email, password}` | 200 / 401 |
| POST | /api/v1/logout | — | 200 |
| GET | /api/v1/me | — | 200 |

---

## Feature 2 — Roles & Permissions
**Goal:** distinguish `customer` vs `admin`.

**Tasks**
- [x] Migration: add `role` (enum, default `customer`) to `users`
- [x] `require_admin!` before_action helper in `BaseController`
- [x] Seed one admin user in `db/seeds.rb`

**Acceptance criteria**
- Customer token hitting an admin-only write endpoint → 403 `{error: "Forbidden"}`
- Admin token hitting the same endpoint → succeeds
- `GET /api/v1/me` reflects the correct `role`

**Endpoints:** none new — this just adds a `require_admin!` guard other features will use.

---

## Feature 3 — Categories
**Goal:** group products.

**Tasks**
- [ ] `Category` model (`name`, presence + uniqueness)
- [ ] Migration: add `category_id` (nullable, indexed) to `products`; `Product belongs_to :category, optional: true`
- [ ] `Api::V1::CategoriesController` — index/show public, create/update/destroy admin-only

**Acceptance criteria**
- `GET /api/v1/categories` works with no auth
- Admin creates with valid name → 201; blank name → 422 `{errors: {name: ["can't be blank"]}}`
- Customer POST → 403
- Deleting a category that has products: pick one policy and enforce it (`dependent: :nullify` or block deletion) — document which

**Endpoints**

| Method | Path | Auth | Body |
|---|---|---|---|
| GET | /api/v1/categories | none | — |
| GET | /api/v1/categories/:id | none | — |
| POST | /api/v1/categories | admin | `{name}` |
| PATCH | /api/v1/categories/:id | admin | `{name}` |
| DELETE | /api/v1/categories/:id | admin | — |

---

## Feature 4 — Product Search, Filter, Pagination
**Goal:** make the existing product index usable at scale.

**Tasks**
- [ ] Add `category_id` and `q` (name search) query params to `ProductsController#index`
- [ ] Add pagination (Kaminari or Pagy), `page`/`per_page` params, default 10, cap 50
- [ ] Response includes a `meta` block; include `category` in product JSON

**Acceptance criteria**
- `?category_id=2` returns only that category's products
- `?q=shirt` matches case-insensitively
- `?page=2&per_page=5` returns the correct slice and correct `meta.total_pages`
- Non-existent `category_id` → empty array, not an error

**Endpoints**

| Method | Path | Response |
|---|---|---|
| GET | /api/v1/products?q=&category_id=&page=&per_page= | `{data: [...], meta: {current_page, total_pages, total_count}}` |

---

## Feature 5 — Shopping Cart
**Goal:** per-user cart that persists across requests.

**Tasks**
- [ ] `Cart belongs_to :user`; `CartItem belongs_to :cart, belongs_to :product`, `quantity:integer`
- [ ] `current_user.cart` — find-or-create on first access
- [ ] `Api::V1::CartController#show`, `Api::V1::CartItemsController#create/#update/#destroy`
- [ ] Cart total computed in a model method, not the controller

**Acceptance criteria**
- Empty cart → `{items: [], total_cents: 0}`
- Adding the same `product_id` twice increments the existing line, doesn't duplicate it
- `PATCH .../items/:id {quantity:0}` — pick one behavior (removes line, or 422) and be consistent
- User A can never see or modify user B's cart items → 404

**Endpoints**

| Method | Path | Body |
|---|---|---|
| GET | /api/v1/cart | — |
| POST | /api/v1/cart/items | `{product_id, quantity}` |
| PATCH | /api/v1/cart/items/:id | `{quantity}` |
| DELETE | /api/v1/cart/items/:id | — |

---

## Feature 6 — Checkout & Orders
**Goal:** turn a cart into an immutable order record.

**Tasks**
- [ ] `Order` (`status` enum: pending/paid/shipped/delivered/cancelled, `total_cents`)
- [ ] `OrderItem` (`quantity`, **`unit_price_cents` — snapshot the price at purchase time**)
- [ ] `Api::V1::OrdersController#create` wraps cart→order conversion in a DB transaction, then empties the cart
- [ ] `#index` (own orders only), `#show` (own order only, else 404)

**Acceptance criteria**
- Checkout with an empty cart → 422 `{error: "Cart is empty"}`
- Successful checkout creates the order, empties the cart, returns 201
- Checkout is atomic — force a mid-transaction failure in a test and confirm `Order.count` didn't change
- Changing a product's price later does **not** change `unit_price_cents` on past `OrderItem`s
- `GET /api/v1/orders/:id` for someone else's order → 404 (don't leak existence with 403)

**Endpoints**

| Method | Path | Body |
|---|---|---|
| POST | /api/v1/orders | — (uses current cart) |
| GET | /api/v1/orders | — |
| GET | /api/v1/orders/:id | — |

---

## Feature 7 — Order Status Management (admin)
**Goal:** admin fulfils orders.

**Tasks**
- [ ] `Api::V1::Admin::OrdersController#index` (all orders, filterable by `status`)
- [ ] `#update` transitions status through a whitelist of valid transitions (e.g. pending→shipped→delivered, pending→cancelled)

**Acceptance criteria**
- Non-admin → 403
- Valid transition (e.g. pending→shipped) → 200
- Invalid transition (e.g. pending→delivered, skipping shipped) → 422 `{error: "Invalid transition"}`

**Endpoints**

| Method | Path | Body |
|---|---|---|
| GET | /api/v1/admin/orders?status= | — |
| PATCH | /api/v1/admin/orders/:id | `{status}` |

---

## Feature 8 — Reviews & Ratings
**Goal:** verified-purchase reviews.

**Tasks**
- [ ] `Review` (`rating` 1–5, `comment`); unique index on `[user_id, product_id]`
- [ ] Guard: user must have an `OrderItem` for that product to review it
- [ ] Add `average_rating` / `reviews_count` to product JSON

**Acceptance criteria**
- Reviewing a product never purchased → 403
- Reviewing a purchased product → 201
- Reviewing the same product twice → 422 (already reviewed)
- `rating` outside 1–5 → 422
- Product show includes `average_rating` rounded to 1 decimal

**Endpoints**

| Method | Path | Body |
|---|---|---|
| GET | /api/v1/products/:id/reviews | — |
| POST | /api/v1/products/:id/reviews | `{rating, comment}` |

---

## Feature 9 — Email Notifications
**Goal:** async, non-blocking order emails.

**Tasks**
- [ ] `OrderMailer#confirmation`, enqueued via `deliver_later` right after checkout (Feature 6)
- [ ] A second mailer enqueued when admin marks an order "shipped" (Feature 7)
- [ ] Configure dev mail delivery (e.g. `letter_opener`) so interns can see it without real SMTP

**Acceptance criteria**
- Checkout enqueues exactly one confirmation email job (`assert_enqueued_email_with` in tests) — never sent synchronously in-request
- Checkout still returns 201 even if mail delivery is simulated as failing (because it's queued, not inline) — this is the actual lesson
- Marking an order "shipped" enqueues the shipped-notification email

---

## Feature 10 — Admin ↔ User Chat (WebSocket / ActionCable)
**Goal:** real-time support chat between a customer and an admin (e.g. attached to an order or a standalone conversation) — teaches WebSockets as a distinct transport from the REST API.

**Prerequisite:** the generic customer-facing `POST /api/v1/login` from Feature 1 (not just the admin one) — customers need an `api_token` too, to authenticate the socket.

**Why WebSocket instead of REST here:** REST is request/response — the client has to poll to see a new message. A chat needs the *server* to push a message to the browser the instant the other side sends it, which is what ActionCable (Rails' WebSocket layer) is for. It runs as its own endpoint (`/cable`), separate from the controller/session stack — this holds true even in an API-only app.

**Tasks**
- [ ] `Conversation` model: `belongs_to :user` (customer), `belongs_to :admin, class_name: "User"` (nullable until an admin picks it up), `status` enum (`open`/`closed`)
- [ ] `Message` model: `belongs_to :conversation`, `belongs_to :sender, class_name: "User"`, `body:text`, presence-validated
- [ ] `mount ActionCable.server => "/cable"` in `config/routes.rb`
- [ ] `ApplicationCable::Connection#connect` — authenticate using a token query param (`wss://.../cable?token=...`), since there's no browser cookie session in the API flow; call `reject_unauthorized_connection` if the token doesn't match a user
- [ ] `ChatChannel#subscribed` — streams from `"conversation_#{params[:conversation_id]}"`, but only after confirming `current_user` is either the conversation's `user` or an `admin`; otherwise `reject`
- [ ] `ChatChannel#speak(data)` — creates a `Message` (persist first, then broadcast — never broadcast something that failed to save)
- [ ] `Api::V1::ConversationsController` — `#index` (customer: own; admin: all/unassigned), `#create` (customer starts one)
- [ ] `Api::V1::Conversations::MessagesController#index` — paginated message history (the socket is for *live* delivery only, not for loading history on page load)

**Acceptance criteria**
- Connecting to `/cable` with a missing/invalid token is rejected — assert with `assert_reject_connection` (or equivalent) in a connection test
- A customer subscribing to another customer's `conversation_id` is rejected server-side, not just hidden in the UI
- An admin can subscribe to any conversation
- Sending a message via `speak` persists a `Message` row **and** is received in real time by the other participant — test with two connected test clients (`ActionCable::Channel::ConnectionStub` / `ActionCable::TestCase`, or two real socket clients in a system test)
- A `speak` call from a user not part of the conversation is rejected server-side (no `Message` row created, nothing broadcast)
- `GET /api/v1/conversations/:id/messages` returns messages oldest→newest, paginated

**Channels & events (WebSocket)**

| Direction | Channel | Action / Event | Payload |
|---|---|---|---|
| Client → Server | `ChatChannel` | `subscribe` | `{ conversation_id }` |
| Client → Server | `ChatChannel` | `speak` | `{ conversation_id, body }` |
| Server → Client | `ChatChannel` | `message` (broadcast) | `{ id, body, sender_id, sender_role, created_at }` |

**REST endpoints (setup & history — not for live delivery)**

| Method | Path | Auth | Body |
|---|---|---|---|
| GET | /api/v1/conversations | customer (own) / admin (all) | — |
| POST | /api/v1/conversations | customer | — |
| GET | /api/v1/conversations/:id/messages?page= | participant only | — |

**Stretch goals**
- "Typing…" indicator broadcast (no DB write, just a transient broadcast)
- "Online/offline" presence for admins
- Auto-close a conversation after N days of inactivity (scheduled job)
