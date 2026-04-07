# Ручное тестирование

> Чеклист для проверки основных сценариев и записи видео-демо.

## Production

| Сервис | URL | Логин |
|--------|-----|-------|
| Сайт | https://ауроспейс.рф | --- |
| Админка | https://ауроспейс.рф/a/ | a / pass |
| API Docs | https://ауроспейс.рф/api-docs | --- |
| Health | https://ауроспейс.рф/up | --- |

---

## Локальная разработка

```bash
docker compose up -d --wait
docker compose exec app bundle exec rails db:prepare db:seed
```

| Сервис | URL | Логин |
|--------|-----|-------|
| React | http://localhost:5173 | --- |
| API | http://localhost:3000 | --- |
| Админка | http://localhost:3000/a | a / pass |
| Sidekiq | http://localhost:3000/a/sidekiq | a / pass |

---

## 1. Создание заказа

- [ ] Открыть http://localhost:5173
- [ ] Выбрать "Demo User 1" в селекторе пользователей
- [ ] Нажать "Create Order", ввести сумму `5000`, отправить
- [ ] **Результат:** заказ создан, статус `created` (синий), сумма 5000 RUB
- [ ] Запомнить **Order ID:** ____
- [ ] Перейти в Account --- баланс **не изменился**

---

## 2. Оплата заказа

- [ ] Открыть заказ из шага 1, нажать кнопку **"Pay"**
- [ ] **Результат:** статус `payment_pending` (жёлтый), появился `external_payment_id`
- [ ] Запомнить **external_payment_id:** ____
- [ ] Кнопка "Pay" исчезла, кнопки "Cancel" нет (только для successful)
- [ ] Account --- баланс **не изменился** (оплата не подтверждена)

---

## 3. Webhook — успешная оплата

- [ ] В терминале отправить (подставить external_payment_id из шага 2):
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"<PAYMENT_ID>"}}'
  ```
- [ ] **Результат:** HTTP 200
- [ ] Обновить страницу заказа: статус `successful` (зелёный), появилась дата `paid_at`
- [ ] Account: баланс **+5000 RUB**
- [ ] В разделе ledger entries заказа: запись `credit` +5000

---

## 4. Отмена заказа (reversal)

- [ ] На странице заказа нажать **"Cancel Order"**
- [ ] **Результат:** статус `cancelled` (красный), появилась дата `cancelled_at`
- [ ] Account: баланс вернулся к прежнему значению (**-5000**)
- [ ] Ledger entries заказа: две записи — `credit` +5000 и `reversal` +5000
- [ ] Кнопок действий нет (заказ в финальном состоянии)

---

## 5. Идемпотентность

- [ ] Отправить **тот же webhook повторно** (тот же payment_id):
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"<ТОТ_ЖЕ_PAYMENT_ID>"}}'
  ```
- [ ] **Результат:** HTTP 200, но ничего не изменилось: заказ всё ещё `cancelled`, баланс тот же, новых ledger записей нет

---

## 6. Защита от повторной отмены

- [ ] Попробовать отменить ещё раз через API:
  ```bash
  curl -s -X POST http://localhost:3000/orders/<ORDER_ID>/cancel
  ```
- [ ] **Результат:** ошибка `already_cancelled` или `invalid_transition`, баланс не изменился

---

## 7. Второй заказ (полный цикл)

- [ ] Создать заказ на `3000` RUB, нажать Pay
- [ ] Отправить webhook с новым payment_id
- [ ] **Результат:** заказ `successful`, баланс **+3000**
- [ ] Account: в ledger entries видны все операции по обоим заказам

---

## 8. Админка

- [ ] Открыть http://localhost:3000/a, ввести a / pass
- [ ] **Dashboard:** видны графики (заказы по статусам, revenue, Sidekiq, таблицы БД)
- [ ] **Orders:** все заказы в списке, фильтр по статусу работает
- [ ] Открыть заказ — видны ledger entries, детали, даты
- [ ] Найти successful заказ, нажать "Cancel Order" — статус меняется на `cancelled`
- [ ] **Webhook Events:** видны все пришедшие вебхуки (processed/duplicate)
- [ ] **Notification Logs:** видны отправленные письма (order_created, payment_successful, order_cancelled)
- [ ] **Accounts:** баланс и история

---

## 9. Edge cases (API)

- [ ] Создать заказ с суммой `0`:
  ```bash
  curl -s -X POST http://localhost:3000/orders \
    -H "Content-Type: application/json" -d '{"user_id":1,"amount_cents":0}'
  ```
  **Результат:** ошибка `invalid_amount`

- [ ] Отменить заказ в статусе `created`:
  ```bash
  curl -s -X POST http://localhost:3000/orders/<CREATED_ID>/cancel
  ```
  **Результат:** ошибка `invalid_transition`

- [ ] Webhook с несуществующим payment_id:
  ```bash
  curl -X POST http://localhost:3000/webhooks/yookassa \
    -H "Content-Type: application/json" \
    -d '{"event":"payment.succeeded","object":{"id":"nonexistent_999"}}'
  ```
  **Результат:** HTTP 200, но баланс не изменился

---

## 10. Quality gates

- [ ] `bin/ci --fast` --- все проверки PASS
- [ ] `bundle exec rspec` --- 229+ тестов, 0 failures
- [ ] `cd frontend && npm run build` --- сборка без ошибок

---

## Завершение

```bash
docker compose down -v
```

---

## Итого: ~30 проверок

| Раздел | Проверок |
|--------|----------|
| 1. Создание заказа | 4 |
| 2. Оплата | 4 |
| 3. Webhook | 4 |
| 4. Отмена | 4 |
| 5. Идемпотентность | 2 |
| 6. Двойная отмена | 2 |
| 7. Второй заказ | 3 |
| 8. Админка | 6 |
| 9. Edge cases | 3 |
| 10. Quality gates | 3 |
| **Итого** | **~35** |
