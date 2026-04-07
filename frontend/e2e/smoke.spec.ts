// e2e/smoke.spec.ts
//
// Smoke tests for critical user flows.
// These verify the system works end-to-end, not UI details.

import { test, expect } from '@playwright/test';

test.describe('Healthcheck', () => {
  test('app is running', async ({ request }) => {
    const response = await request.get('/up');
    expect(response.ok()).toBeTruthy();
  });

  test('admin panel responds', async ({ request }) => {
    const response = await request.get('/admin', {
      headers: {
        Authorization: `Basic ${Buffer.from('admin:password').toString('base64')}`,
      },
    });
    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Orders flow', () => {
  test('orders page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('body')).toBeVisible();
  });

  test('can view order list', async ({ page }) => {
    await page.goto('/orders');
    await expect(page.locator('body')).toBeVisible();
  });

  // TODO: expand with full payment flow smoke test
  // 1. Create order
  // 2. Initiate payment
  // 3. Simulate webhook (via API)
  // 4. Verify order status changed
  // 5. Verify ledger entry created
  // 6. Cancel order
  // 7. Verify reversal
});

test.describe('API endpoints', () => {
  test('GET /orders returns JSON', async ({ request }) => {
    const response = await request.get('/orders', {
      headers: { Accept: 'application/json' },
    });
    expect(response.ok()).toBeTruthy();
    expect(response.headers()['content-type']).toContain('json');
  });
});
