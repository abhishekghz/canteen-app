import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { lineTotal, Pricing, seedPricing } from "./pricing";

initializeApp();
const db = getFirestore();

async function loadPricing(): Promise<Pricing> {
  const doc = await db.collection("config").doc("pricing").get();
  return doc.exists ? (doc.data() as Pricing) : seedPricing;
}

function requireAuth(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  return uid;
}

/**
 * Places an order with server-computed totals so clients cannot tamper with
 * prices. Expects { lines: [...], paymentStatus }.
 */
export const placeOrder = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  const lines = (req.data?.lines ?? []) as any[];
  if (!Array.isArray(lines) || lines.length === 0) {
    throw new HttpsError("invalid-argument", "Order has no lines.");
  }
  const pricing = await loadPricing();

  const pricedLines = lines.map((l) => ({ ...l, lineTotal: lineTotal(pricing, l) }));
  const total = pricedLines.reduce((s, l) => s + l.lineTotal, 0);

  const ref = await db.collection("orders").add({
    uid,
    createdAt: new Date().toISOString(),
    lines: pricedLines,
    total,
    status: "confirmed",
    paymentStatus: req.data?.paymentStatus === "paid" ? "paid" : "unpaid",
  });
  return { orderId: ref.id, total };
});

/** Admin-only: change an order's payment status. */
export const setPaymentStatus = onCall(async (req) => {
  requireAuth(req.auth?.uid);
  if (req.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
  const { orderId, status } = req.data ?? {};
  if (!["unpaid", "paid", "refunded"].includes(status)) {
    throw new HttpsError("invalid-argument", "Bad status.");
  }
  await db.collection("orders").doc(orderId).update({ paymentStatus: status });
  return { ok: true };
});

/** Buy prepaid meal coupons (priced server-side). */
export const buyCoupons = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  const { mealType, qty } = req.data ?? {};
  if (!["breakfast", "lunch", "dinner"].includes(mealType)) {
    throw new HttpsError("invalid-argument", "Bad meal type.");
  }
  const n = Math.max(1, Math.min(50, Number(qty) || 1));
  const pricing = await loadPricing();
  const unit = (pricing as any)[mealType] as number;

  const now = new Date();
  const expires = new Date(now.getTime() + 30 * 24 * 3600 * 1000);
  const batch = db.batch();
  const created: string[] = [];
  for (let i = 0; i < n; i++) {
    const ref = db.collection("coupons").doc();
    batch.set(ref, {
      uid,
      mealType,
      code: ref.id.substring(0, 6).toUpperCase(),
      status: "active",
      purchasedAt: now.toISOString(),
      expiresAt: expires.toISOString(),
    });
    created.push(ref.id);
  }
  await batch.commit();
  return { couponIds: created, total: unit * n };
});

/** Admin-only: grant/revoke admin claim on another user. */
export const setAdminClaim = onCall(async (req) => {
  requireAuth(req.auth?.uid);
  if (req.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
  const { targetUid, admin } = req.data ?? {};
  await getAuth().setCustomUserClaims(targetUid, { admin: admin === true });
  await db.collection("users").doc(targetUid).set(
    { role: admin === true ? "admin" : "student" },
    { merge: true }
  );
  return { ok: true };
});

/**
 * One-time bootstrap: seeds pricing/menu/snack config and creates the default
 * admin account with the admin claim. Guarded by a setup secret so it can't be
 * called by anyone. Call once, then remove the secret.
 *   data: { setupSecret, email, password }
 * Set the expected secret via:  firebase functions:config or env SETUP_SECRET.
 */
export const bootstrap = onCall(async (req) => {
  const expected = process.env.SETUP_SECRET;
  if (!expected || req.data?.setupSecret !== expected) {
    throw new HttpsError("permission-denied", "Bad setup secret.");
  }
  const email = req.data?.email ?? "admin@canteen.app";
  const password = req.data?.password ?? "admin123";

  // Create or fetch the admin user, then set the claim.
  const auth = getAuth();
  let uid: string;
  try {
    const existing = await auth.getUserByEmail(email);
    uid = existing.uid;
  } catch {
    const created = await auth.createUser({ email, password });
    uid = created.uid;
  }
  await auth.setCustomUserClaims(uid, { admin: true });
  await db.collection("users").doc(uid).set({
    name: "Canteen Admin",
    email,
    role: "admin",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Seed pricing.
  await db.collection("config").doc("pricing").set(seedPricing);

  // Seed snack slots.
  await db.collection("config").doc("snackSlots").set({
    slots: [
      { id: "morning", label: "Morning Snacks", time: "11:00" },
      { id: "evening", label: "Evening Snacks", time: "16:30" },
    ],
  });

  // Seed a starter week.
  const week: Record<string, { breakfast: string[]; lunch: string[]; dinner: string[] }> = {
    mon: { breakfast: ["Poha", "Tea"], lunch: ["Roti", "Dal", "Aloo Sabji", "Rice"], dinner: ["Roti", "Paneer", "Rice"] },
    tue: { breakfast: ["Idli", "Sambar"], lunch: ["Roti", "Rajma", "Rice", "Salad"], dinner: ["Roti", "Mix Veg", "Rice"] },
    wed: { breakfast: ["Paratha", "Curd"], lunch: ["Roti", "Chole", "Rice", "Papad"], dinner: ["Roti", "Bhindi", "Dal", "Rice"] },
    thu: { breakfast: ["Upma", "Coffee"], lunch: ["Roti", "Kadhi", "Rice", "Salad"], dinner: ["Roti", "Aloo Gobi", "Rice"] },
    fri: { breakfast: ["Dosa", "Chutney"], lunch: ["Roti", "Dal Fry", "Jeera Rice"], dinner: ["Roti", "Matar Paneer", "Rice"] },
    sat: { breakfast: ["Aloo Puri"], lunch: ["Veg Biryani", "Raita"], dinner: ["Roti", "Egg Curry / Soya", "Rice"] },
    sun: { breakfast: ["Chole Bhature"], lunch: ["Special Thali"], dinner: ["Fried Rice", "Manchurian"] },
  };
  const batch = db.batch();
  for (const [day, meals] of Object.entries(week)) {
    batch.set(db.collection("menu").doc(day), { weekday: day, ...meals });
  }
  await batch.commit();

  logger.info(`Bootstrap complete. Admin uid=${uid}`);
  return { ok: true, adminUid: uid };
});
