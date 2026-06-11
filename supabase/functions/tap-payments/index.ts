import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const TAP_SECRET_KEY = Deno.env.get("TAP_SECRET_KEY") ?? "";
const TAP_API_BASE = "https://api.tap.company/v2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json() as Record<string, unknown>;
    const action = body.action as string | undefined;

    if (action === "create-charge") return await handleCreateCharge(body);
    if (action === "verify-charge") return await handleVerifyCharge(body);

    return json({ error: "Unknown action" }, 400);
  } catch (err) {
    return json({ error: `Internal error: ${err}` }, 500);
  }
});

// ── Create charge ─────────────────────────────────────────────────────────────

async function handleCreateCharge(body: Record<string, unknown>): Promise<Response> {
  const {
    amount,
    currency,
    customerFirstName,
    customerCountryCode,
    customerPhone,
    description,
    redirectUrl,
  } = body as {
    amount: number;
    currency: string;
    customerFirstName: string;
    customerCountryCode: string;
    customerPhone: string;
    description: string;
    redirectUrl: string;
  };

  const ts = Date.now();

  const tapRes = await fetch(`${TAP_API_BASE}/charges`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${TAP_SECRET_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount,
      currency,
      customer_initiated: true,
      threeDSecure: true,
      save_card: false,
      description,
      reference: {
        transaction: `txn_${ts}`,
        order: `ord_${ts}`,
      },
      receipt: { email: false, sms: false },
      customer: {
        first_name: customerFirstName,
        phone: { country_code: customerCountryCode, number: customerPhone },
      },
      merchant: { id: "" },
      source: { id: "src_all" },
      redirect: { url: redirectUrl },
    }),
  });

  const data = await tapRes.json() as Record<string, unknown>;

  if (!tapRes.ok) {
    return json({ error: `Tap API ${tapRes.status}: ${JSON.stringify(data)}` }, 502);
  }

  const checkoutUrl =
    (data.transaction as Record<string, unknown> | undefined)?.url as string | undefined;

  if (!checkoutUrl) {
    return json({ error: "No checkout URL in Tap response" }, 502);
  }

  return json({ chargeId: data.id as string, checkoutUrl });
}

// ── Verify charge ─────────────────────────────────────────────────────────────

async function handleVerifyCharge(body: Record<string, unknown>): Promise<Response> {
  const { chargeId } = body as { chargeId: string };

  const tapRes = await fetch(`${TAP_API_BASE}/charges/${chargeId}`, {
    headers: { Authorization: `Bearer ${TAP_SECRET_KEY}` },
  });

  const data = await tapRes.json() as Record<string, unknown>;

  if (!tapRes.ok) {
    return json({ error: `Tap API ${tapRes.status}: ${JSON.stringify(data)}` }, 502);
  }

  return json({ status: data.status as string });
}
