# Manual Testing Plan

> Step-by-step manual testing checklist for AUROSPACE Orders Demo.
> Each step has: what to do, where to do it, what to enter, and expected result.
> Check off each step as you go.

---

## Prerequisites

```bash
# 1. Start all services
docker compose up -d --wait

# 2. Seed demo data
docker compose exec app bundle exec rails db:prepare db:seed

# 3. Verify services
curl -s http://localhost:3000/up
# Expected: {"status":"ok"}
```

| Service | URL | Credentials |
|---------|-----|-------------|
| React Frontend | http://localhost:5173 | --- |
| Rails API | http://localhost:3000 | --- |
| ActiveAdmin | http://localhost:3000/admin | admin / password |
| Sidekiq Web | http://localhost:3000/admin/sidekiq | admin / password |

---

## 1. React Frontend — Initial State

### 1.1 Dashboard loads
- [ ] **Go to:** http://localhost:5173
- [ ] **Action:** Page loads without errors
- [ ] **Expected:** Dashboard page with navigation header (Dashboard, Orders, Account, API Docs, Admin Panel)
- [ ] **Expected:** Demo user selector in header showing "Demo User 1"
- [ ] **Expected:** Balance card showing current balance
- [ ] **Expected:** Summary cards (Total Orders, Successful, Pending, Cancelled)
- [ ] **Expected:** Recent orders section

### 1.2 Demo user switching
- [ ] **Action:** Click demo user selector in header
- [ ] **Action:** Switch to "Demo User 2"
- [ ] **Expected:** Dashboard updates — different balance, different orders
- [ ] **Action:** Switch back to "Demo User 1"
- [ ] **Expected:** Dashboard shows Demo User 1 data again

### 1.3 Navigation works
- [ ] **Action:** Click "Orders" in nav
- [ ] **Expected:** Orders list page loads at `/orders`
- [ ] **Action:** Click "Account" in nav
- [ ] **Expected:** Account page loads showing balance and ledger entries
- [ ] **Action:** Click "Dashboard" in nav
- [ ] **Expected:** Back to dashboard
- [ ] **Action:** Click "Admin Panel" link
- [ ] **Expected:** Opens `/admin` (Basic Auth prompt in new tab)
- [ ] **Action:** Click "API Docs" link
- [ ] **Expected:** Opens API docs page

---

## 2. Create Order

### 2.1 Create order form
- [ ] **Go to:** http://localhost:5173
- [ ] **Action:** Click "Create Order" button
- [ ] **Expected:** Order creation form appears (amount input field)

### 2.2 Validation — empty amount
- [ ] **Action:** Leave amount empty, click Submit
- [ ] **Expected:** Validation error shown, order NOT created

### 2.3 Validation — zero amount
- [ ] **Action:** Enter `0`, click Submit
- [ ] **Expected:** Error: amount must be positive

### 2.4 Successful creation
- [ ] **Action:** Enter `5000` in amount field
- [ ] **Action:** Click Submit
- [ ] **Expected:** Order created successfully
- [ ] **Expected:** Redirected to order detail page
- [ ] **Expected:** Order status: `created` (blue badge)
- [ ] **Expected:** Amount: 5000 RUB
- [ ] **Expected:** `created_at` timestamp shown
- [ ] **Expected:** `paid_at` empty
- [ ] **Expected:** `cancelled_at` empty
- [ ] **Note down:** Order ID = ____

### 2.5 Order appears in list
- [ ] **Action:** Click "Orders" in nav
- [ ] **Expected:** New order visible in the list with status `created`
- [ ] **Expected:** Amount shows 5000 RUB

### 2.6 Balance unchanged
- [ ] **Action:** Click "Account" in nav
- [ ] **Expected:** Balance has NOT changed (order not paid yet)

---

## 3. Initiate Payment

### 3.1 Pay button visible
- [ ] **Go to:** Order detail page (click on the order from step 2.4)
- [ ] **Expected:** "Pay" button is visible (order is `created`)
- [ ] **Expected:** "Cancel" button is NOT visible (only for `successful`)

### 3.2 Click Pay
- [ ] **Action:** Click "Pay" button
- [ ] **Expected:** Status changes to `payment_pending` (yellow badge)
- [ ] **Expected:** `payment_provider` shows "yookassa"
- [ ] **Expected:** `external_payment_id` is now set
- [ ] **Note down:** external_payment_id = ____

### 3.3 Buttons updated
- [ ] **Expected:** "Pay" button is GONE
- [ ] **Expected:** "Cancel" button is NOT visible (only for `successful`)
- [ ] **Expected:** Status badge shows "payment_pending"

### 3.4 Balance still unchanged
- [ ] **Action:** Click "Account" in nav
- [ ] **Expected:** Balance has NOT changed (payment not confirmed)

---

## 4. Simulate Payment Success (Webhook)

### 4.1 Send webhook
- [ ] **Go to:** Terminal
- [ ] **Action:** Run (replace `<PAYMENT_ID>` with external_payment_id from step 3.2):
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"<PAYMENT_ID>"}}'
  ```
- [ ] **Expected:** HTTP 200 (empty response, no error)

### 4.2 Order status updated
- [ ] **Go to:** React app, order detail page
- [ ] **Action:** Refresh page
- [ ] **Expected:** Status changed to `successful` (green badge)
- [ ] **Expected:** `paid_at` timestamp is now set

### 4.3 Balance increased
- [ ] **Action:** Click "Account" in nav
- [ ] **Expected:** Balance increased by 5000 RUB

### 4.4 Ledger entry created
- [ ] **Expected:** New ledger entry visible:
  - Type: `credit`
  - Amount: 5000 RUB
  - Reference: contains payment ID

### 4.5 Order detail shows ledger
- [ ] **Action:** Go back to order detail page
- [ ] **Expected:** Ledger entries section shows `credit` +5000

---

## 5. Cancel Order (Reversal)

### 5.1 Cancel button visible
- [ ] **Go to:** Order detail page (the successful order)
- [ ] **Expected:** "Cancel Order" button is visible (order is `successful`)
- [ ] **Expected:** "Pay" button is NOT visible

### 5.2 Click Cancel
- [ ] **Action:** Click "Cancel Order" button
- [ ] **Expected:** Status changes to `cancelled` (red badge)
- [ ] **Expected:** `cancelled_at` timestamp is now set

### 5.3 Balance restored
- [ ] **Action:** Click "Account" in nav
- [ ] **Expected:** Balance decreased by 5000 RUB (back to previous value)

### 5.4 Reversal ledger entry
- [ ] **Expected:** TWO ledger entries for this order:
  1. `credit` +5000 (from payment)
  2. `reversal` +5000 (compensating entry)

### 5.5 Order is now read-only
- [ ] **Action:** Go back to order detail
- [ ] **Expected:** No action buttons (no Pay, no Cancel)
- [ ] **Expected:** Status: `cancelled` (red badge)

---

## 6. Idempotency — Duplicate Webhook

### 6.1 Send same webhook again
- [ ] **Go to:** Terminal
- [ ] **Action:** Run the SAME curl command from step 4.1 (same payment_id):
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"<SAME_PAYMENT_ID>"}}'
  ```
- [ ] **Expected:** HTTP 200 (no error)

### 6.2 Nothing changed
- [ ] **Go to:** React app
- [ ] **Expected:** Order still `cancelled`
- [ ] **Expected:** Balance unchanged
- [ ] **Expected:** No new ledger entries
- [ ] **Expected:** No duplicate email sent

---

## 7. Double Cancel Protection

### 7.1 Try to cancel again via API
- [ ] **Go to:** Terminal
- [ ] **Action:** Run:
  ```bash
  curl -X POST http://localhost:3000/orders/<ORDER_ID>/cancel \
    -H "Content-Type: application/json"
  ```
- [ ] **Expected:** Error response: `already_cancelled` or `invalid_transition`
- [ ] **Expected:** Balance unchanged
- [ ] **Expected:** No new reversal entry

---

## 8. Create and Pay Second Order

### 8.1 Create
- [ ] **Go to:** React app, click "Create Order"
- [ ] **Action:** Enter `3000` RUB, submit
- [ ] **Expected:** New order created with status `created`
- [ ] **Note down:** Order ID = ____, external_payment_id = ____

### 8.2 Pay
- [ ] **Action:** Click "Pay" on the new order
- [ ] **Expected:** Status: `payment_pending`
- [ ] **Note down:** external_payment_id = ____

### 8.3 Webhook
- [ ] **Go to:** Terminal
- [ ] **Action:** Send webhook for the new order's payment_id
- [ ] **Expected:** HTTP 200

### 8.4 Verify
- [ ] **Go to:** React app
- [ ] **Expected:** Order status: `successful`
- [ ] **Expected:** Balance increased by 3000 RUB
- [ ] **Expected:** New `credit` ledger entry

---

## 9. ActiveAdmin Backoffice

### 9.1 Login
- [ ] **Go to:** http://localhost:3000/admin
- [ ] **Action:** Enter credentials: `admin` / `password`
- [ ] **Expected:** Admin dashboard loads

### 9.2 Dashboard charts
- [ ] **Expected:** "Orders by Status" pie chart visible
- [ ] **Expected:** "Orders per Day" line chart visible
- [ ] **Expected:** "Revenue" chart visible
- [ ] **Expected:** Summary table: Total Orders, Successful, Revenue, Accounts, Balance
- [ ] **Expected:** Sidekiq panel: Processed, Failed, Enqueued counts
- [ ] **Expected:** Database panel: table names with row counts

### 9.3 Orders
- [ ] **Action:** Click "Orders" in admin sidebar
- [ ] **Expected:** All orders listed with columns: ID, User, Amount, Status, Paid At, Created At
- [ ] **Action:** Filter by status "successful"
- [ ] **Expected:** Only successful orders shown
- [ ] **Action:** Click on a successful order
- [ ] **Expected:** Order detail with "Ledger Entries" panel showing credit entries
- [ ] **Expected:** "Cancel Order" button visible for successful orders

### 9.4 Cancel from admin
- [ ] **Action:** Find a successful order, click "Cancel Order"
- [ ] **Expected:** Order status changes to `cancelled`
- [ ] **Expected:** Reversal ledger entry created
- [ ] **Expected:** Account balance updated

### 9.5 Accounts
- [ ] **Action:** Click "Accounts" in admin sidebar
- [ ] **Expected:** Accounts listed with user email, balance, currency
- [ ] **Action:** Click on an account
- [ ] **Expected:** Account detail with ledger entries panel

### 9.6 Ledger Entries
- [ ] **Action:** Click "Ledger Entries" in admin sidebar
- [ ] **Expected:** All entries listed: ID, Account, Order, Type, Amount, Reference, Date
- [ ] **Action:** Filter by entry type "reversal"
- [ ] **Expected:** Only reversal entries shown
- [ ] **Expected:** Read-only (no edit/delete buttons)

### 9.7 Webhook Events
- [ ] **Action:** Click "Webhook Events" in admin sidebar
- [ ] **Expected:** All webhook events listed
- [ ] **Action:** Click on an event
- [ ] **Expected:** Full JSON payload displayed
- [ ] **Expected:** Status shown (processed / failed / duplicate)
- [ ] **Expected:** Read-only

### 9.8 Notification Logs
- [ ] **Action:** Click "Notification Logs" in admin sidebar
- [ ] **Expected:** All notification logs listed: Order, Mail Type, Recipient, Sent At
- [ ] **Expected:** Multiple types: `order_created`, `payment_successful`, `order_cancelled`
- [ ] **Expected:** Read-only

### 9.9 Sidekiq Web UI
- [ ] **Go to:** http://localhost:3000/admin/sidekiq
- [ ] **Expected:** Sidekiq dashboard loads (queues, processed/failed stats)

---

## 10. API Direct Testing

### 10.1 List orders
- [ ] **Run:**
  ```bash
  curl -s http://localhost:3000/orders?user_id=1 | python3 -m json.tool
  ```
- [ ] **Expected:** JSON array of orders for user 1

### 10.2 Show order
- [ ] **Run:**
  ```bash
  curl -s http://localhost:3000/orders/<ORDER_ID> | python3 -m json.tool
  ```
- [ ] **Expected:** JSON with order details + ledger_entries

### 10.3 Show account
- [ ] **Run:**
  ```bash
  curl -s http://localhost:3000/accounts/<ACCOUNT_ID> | python3 -m json.tool
  ```
- [ ] **Expected:** JSON with balance_cents, currency, ledger_entries

### 10.4 Create order via API
- [ ] **Run:**
  ```bash
  curl -s -X POST http://localhost:3000/orders \
    -H "Content-Type: application/json" \
    -d '{"user_id":1,"amount_cents":7777}' | python3 -m json.tool
  ```
- [ ] **Expected:** JSON with new order, status "created", amount_cents 7777

### 10.5 Invalid amount
- [ ] **Run:**
  ```bash
  curl -s -X POST http://localhost:3000/orders \
    -H "Content-Type: application/json" \
    -d '{"user_id":1,"amount_cents":0}' | python3 -m json.tool
  ```
- [ ] **Expected:** Error response: `invalid_amount`

### 10.6 Health endpoints
- [ ] **Run:** `curl -s http://localhost:3000/up`
- [ ] **Expected:** `{"status":"ok"}`
- [ ] **Run:** `curl -s http://localhost:3000/health | python3 -m json.tool`
- [ ] **Expected:** JSON with `app: ok`, `database: ok`, `redis: ok`

---

## 11. Quality Gates

### 11.1 RSpec
- [ ] **Run:** `bundle exec rspec`
- [ ] **Expected:** 229+ examples, 0 failures

### 11.2 RuboCop
- [ ] **Run:** `bundle exec rubocop`
- [ ] **Expected:** 0 offenses

### 11.3 Brakeman
- [ ] **Run:** `bundle exec brakeman -q --no-pager`
- [ ] **Expected:** 0 warnings

### 11.4 Full local CI
- [ ] **Run:** `bin/ci --fast`
- [ ] **Expected:** All PASS, 0 FAIL

### 11.5 Frontend build
- [ ] **Run:** `cd frontend && npm run build`
- [ ] **Expected:** Build succeeds without errors

---

## 12. Edge Cases

### 12.1 Pay already paid order
- [ ] **Action:** Via API, try to pay a `payment_pending` order again
  ```bash
  curl -s -X POST http://localhost:3000/orders/<PENDING_ORDER_ID>/pay
  ```
- [ ] **Expected:** Error: `invalid_transition` (can't pay twice)

### 12.2 Cancel unpaid order
- [ ] **Action:** Via API, try to cancel a `created` order
  ```bash
  curl -s -X POST http://localhost:3000/orders/<CREATED_ORDER_ID>/cancel
  ```
- [ ] **Expected:** Error: `invalid_transition` (only successful can be cancelled)

### 12.3 Webhook for unknown payment
- [ ] **Run:**
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"nonexistent_payment_999"}}'
  ```
- [ ] **Expected:** HTTP 200 (webhook accepted but order not found)
- [ ] **Expected:** No balance changes anywhere

### 12.4 Malformed webhook
- [ ] **Run:**
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d 'not json at all'
  ```
- [ ] **Expected:** HTTP 400 (bad request)

---

## Teardown

```bash
docker compose down -v
```

---

## Summary Checklist

| Section | Steps | Status |
|---------|-------|--------|
| 1. Frontend Initial State | 12 | [ ] |
| 2. Create Order | 10 | [ ] |
| 3. Initiate Payment | 7 | [ ] |
| 4. Webhook Success | 8 | [ ] |
| 5. Cancel + Reversal | 8 | [ ] |
| 6. Idempotency | 5 | [ ] |
| 7. Double Cancel | 3 | [ ] |
| 8. Second Order | 7 | [ ] |
| 9. ActiveAdmin | 17 | [ ] |
| 10. API Direct | 9 | [ ] |
| 11. Quality Gates | 5 | [ ] |
| 12. Edge Cases | 7 | [ ] |
| **Total** | **~98 checks** | |
