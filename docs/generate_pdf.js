const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const SHOTS = '/Users/abhishekgautam/Desktop/Canteen app/docs/screenshots';
const OUT = '/Users/abhishekgautam/Desktop/Canteen app/dist/Canteen-App-User-Guide.pdf';

const img = (name) => {
  const b64 = fs.readFileSync(path.join(SHOTS, name + '.png')).toString('base64');
  return `data:image/png;base64,${b64}`;
};

// section: [screenshot(s), title, bullet points]
const sections = [
  ['01_login', 'Log in / Register', [
    'Students tap <b>“New here? Create an account”</b> to register with name, email and a password (min 6 characters).',
    'Returning users enter their email and password and tap <b>Log in</b>.',
    'The <b>Admin</b> signs in with the default admin account (see the box on the cover) — no registration needed.', 'Need help? The admin contact (<b>Abhishek Gautam · gautam.abhishek7100@gmail.com</b>) is shown at the bottom of the login screen and under the in-app menu.',
  ]],
  ['02_menu', 'Weekly Menu', [
    'The first tab shows the canteen’s weekly menu — breakfast, lunch and dinner for every day.',
    'The admin can edit this at any time; changes appear here instantly.',
  ]],
  ['03_booking', 'Book a Meal', [
    'Pick <b>Breakfast</b>, <b>Lunch</b> or <b>Dinner</b> (₹50 each) and choose the date.',
    'Add optional extras and packing (next page), then tap <b>Add to cart</b>.',
  ]],
  ['04_booking_extras', 'Extras & Packing', [
    'Add <b>Extra roti</b> (₹5 each) and <b>Extra sabji</b> (₹20 each) with the +/− steppers.',
    'Turn on <b>Pack this meal</b> to add the ₹15 packing charge.',
    'The <b>Line total</b> updates live — here ₹50 + 2 roti + 1 sabji + packing = <b>₹95</b>.',
  ]],
  ['05_snacks', 'Snacks', [
    'Two snack times: <b>Morning</b> and <b>Evening</b> (times set by admin).',
    'Choose <b>Book now</b> for today or <b>Early booking</b> for a future date.',
    'Add <b>Tea/Coffee</b> (₹10) and <b>Snacks</b> (₹20), then add to cart.',
  ]],
  ['06_coupons', 'Coupons', [
    'Buy prepaid meal coupons in advance for Breakfast, Lunch or Dinner.',
    'Pick a meal type and quantity, then tap <b>Buy</b>. Your coupons are listed below with a code and can be redeemed later.',
  ]],
  ['07_cart', 'Cart', [
    'The cart lists every item with its price and the overall <b>Total</b>.',
    'Remove an item with the trash icon, or tap <b>Proceed to payment</b>.',
  ]],
  ['08_payment', 'Payment', [
    'The payment screen shows the amount due.',
    'A real payment gateway isn’t connected yet — this is a placeholder that simulates a successful payment. Tap <b>Pay</b> to continue.',
  ]],
  ['09_payment_success', 'Order Confirmed', [
    'After paying, you get a <b>Payment successful</b> confirmation and the order is placed.',
    'Tap <b>Done</b> to return to the app.',
  ]],
  ['10_orders', 'My Orders', [
    'The <b>Orders</b> tab lists all your bookings with date, total and a payment-status chip (<b>Paid</b> / <b>Unpaid</b>).',
    'Tap an order to expand it and see each item.',
  ]],
  ['11_admin_dashboard', 'Admin — Dashboard', [
    'When the admin logs in, they see the <b>Admin Dashboard</b> instead of the student home.',
    'Four tools: Weekly Menu, Charges, Orders & Payments, Snack Slots.',
    'The <b>☁️ upload icon</b> (top-right) seeds the initial menu/prices if needed.',
  ]],
  ['12_admin_charges', 'Admin — Charges', [
    'Edit every price: meals, extra roti, extra sabji, packing, tea/coffee, snacks and any early-booking discount.',
    'Tap <b>Save charges</b> — new prices apply across the whole app immediately.',
  ]],
  ['13_admin_menu_editor', 'Admin — Weekly Menu Editor', [
    'Expand any day and edit the breakfast / lunch / dinner items (one per line).',
    'Tap <b>Save day</b> — students see the updated menu right away.',
  ]],
  ['14_admin_orders', 'Admin — Orders & Payments', [
    'See every order from all users. Expand one to view its items.',
    'Change the <b>Payment status</b> (Unpaid / Paid / Refunded) from the dropdown.',
  ]],
];

const sectionHtml = (s, i) => `
  <section class="page">
    <div class="phead"><span class="num">${i + 1}</span><h2>${s[1]}</h2></div>
    <div class="row">
      <div class="shot"><img src="${img(s[0])}"/></div>
      <div class="text"><ul>${s[2].map((b) => `<li>${b}</li>`).join('')}</ul></div>
    </div>
    <div class="foot">Canteen App — User Guide</div>
  </section>`;

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  @page { size: A4; margin: 0; }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #26201c; }
  .page { width: 210mm; height: 297mm; padding: 16mm 16mm 12mm; page-break-after: always; position: relative; display: flex; flex-direction: column; }
  .cover { background: #E85D04; color: #fff; align-items: center; justify-content: center; text-align: center; }
  .cover .logo { font-size: 64px; margin-bottom: 8px; }
  .cover h1 { font-size: 40px; margin: 0 0 6px; }
  .cover p.sub { font-size: 17px; opacity: .95; margin: 0 0 34px; }
  .creds { background: #fff; color: #26201c; border-radius: 14px; padding: 22px 28px; width: 118mm; box-shadow: 0 10px 30px rgba(0,0,0,.18); }
  .creds h3 { margin: 0 0 12px; color: #E85D04; font-size: 18px; }
  .creds table { width: 100%; border-collapse: collapse; font-size: 15px; }
  .creds td { padding: 6px 4px; border-bottom: 1px solid #eee; }
  .creds td.k { color: #7a726c; width: 42%; }
  .creds td.v { font-weight: 700; font-family: ui-monospace, Menlo, monospace; }
  .creds .note { margin-top: 12px; font-size: 12.5px; color: #7a726c; }
  .phead { display: flex; align-items: center; gap: 12px; border-bottom: 3px solid #E85D04; padding-bottom: 10px; margin-bottom: 14px; }
  .phead .num { background: #E85D04; color: #fff; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 16px; flex: none; }
  .phead h2 { margin: 0; font-size: 24px; }
  .row { display: flex; gap: 14mm; flex: 1; align-items: flex-start; }
  .shot img { height: 205mm; width: auto; border: 1px solid #e7ddd6; border-radius: 12px; box-shadow: 0 6px 18px rgba(0,0,0,.10); }
  .text { flex: 1; padding-top: 6mm; }
  .text ul { margin: 0; padding-left: 20px; }
  .text li { font-size: 15.5px; line-height: 1.6; margin-bottom: 14px; }
  .foot { position: absolute; bottom: 8mm; left: 16mm; right: 16mm; border-top: 1px solid #eee; padding-top: 6px; font-size: 11px; color: #a99f98; display: flex; justify-content: space-between; }
  .toc h2 { color: #E85D04; }
  .toc ol { font-size: 15px; line-height: 2; }
</style></head><body>
  <section class="page cover">
    <div class="logo">🍽️</div>
    <h1>Canteen App</h1>
    <p class="sub">User Guide &amp; Walkthrough</p>
    <div class="creds">
      <h3>Admin login</h3>
      <table>
        <tr><td class="k">Email / ID</td><td class="v">admin@canteen.app</td></tr>
        <tr><td class="k">Password</td><td class="v">admin123</td></tr>
      </table>
      <div class="note">Students create their own account from the login screen (“Create an account”). The admin account above is pre-created and manages the menu, prices and payments.</div>
    </div>
  </section>
  ${sections.map(sectionHtml).join('')}
</body></html>`;

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle0' });
  await page.pdf({ path: OUT, format: 'A4', printBackground: true });
  await browser.close();
  console.log('PDF written:', OUT);
})().catch((e) => { console.error(e); process.exit(1); });
