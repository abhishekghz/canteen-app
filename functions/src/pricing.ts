// Authoritative pricing — mirrors lib/domain/pricing/pricing_engine.dart.
// Keep the two in sync. All amounts are integer paise.

export interface Pricing {
  breakfast: number;
  lunch: number;
  dinner: number;
  roti: number;
  sabji: number;
  packing: number;
  teaCoffee: number;
  snack: number;
  earlyBookingDiscount: number;
}

export const seedPricing: Pricing = {
  breakfast: 5000,
  lunch: 5000,
  dinner: 5000,
  roti: 500,
  sabji: 2000,
  packing: 1500,
  teaCoffee: 1000,
  snack: 2000,
  earlyBookingDiscount: 0,
};

export type MealType = "breakfast" | "lunch" | "dinner";

export function basePrice(p: Pricing, type: MealType): number {
  return p[type];
}

export function mealLineTotal(
  p: Pricing,
  opts: { type: MealType; extraRoti?: number; extraSabji?: number; packed?: boolean }
): number {
  const roti = opts.extraRoti ?? 0;
  const sabji = opts.extraSabji ?? 0;
  return (
    basePrice(p, opts.type) +
    roti * p.roti +
    sabji * p.sabji +
    (opts.packed ? p.packing : 0)
  );
}

export function snackLineTotal(
  p: Pricing,
  opts: { teaCoffeeQty?: number; snackQty?: number; earlyBooking?: boolean }
): number {
  const tea = opts.teaCoffeeQty ?? 0;
  const snack = opts.snackQty ?? 0;
  const gross = tea * p.teaCoffee + snack * p.snack;
  const net = gross - (opts.earlyBooking ? p.earlyBookingDiscount : 0);
  return net < 0 ? 0 : net;
}

/* eslint-disable @typescript-eslint/no-explicit-any */
export function lineTotal(p: Pricing, line: any): number {
  if (line.kind === "meal") {
    return mealLineTotal(p, {
      type: line.mealType,
      extraRoti: line.extraRoti,
      extraSabji: line.extraSabji,
      packed: line.packed,
    });
  }
  return snackLineTotal(p, {
    teaCoffeeQty: line.teaCoffeeQty,
    snackQty: line.snackQty,
    earlyBooking: line.earlyBooking,
  });
}
