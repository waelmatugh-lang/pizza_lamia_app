import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Generates an OAuth2 access token for FCM using the private key
async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  // Ensure private key handles literal \n correctly if passed from env
  const formattedKey = privateKey.replace(/\\n/g, '\n');

  const privateKeyObj = await importPKCS8(formattedKey, 'RS256');

  // Create JWT for Google OAuth2
  const tokenUrl = 'https://oauth2.googleapis.com/token';
  const scope = 'https://www.googleapis.com/auth/firebase.messaging';

  const jwt = await new SignJWT({
    iss: clientEmail,
    scope: scope,
    aud: tokenUrl,
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h') // Token expires in 1 hour
    .sign(privateKeyObj);

  // Exchange JWT for Access Token
  const response = await fetch(tokenUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to get OAuth token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Setup Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    
    // We use service role key to bypass RLS and read user_tokens table securely
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Parse Webhook Event Payload (from `orders` table updates)
    const payload = await req.json();
    console.log("Webhook Payload Received:", payload);

    const record = payload.record;
    if (!record || !record.user_id || !record.status) {
      throw new Error("Invalid payload: Missing record, user_id, or status.");
    }

    const userId = record.user_id;
    const newStatus = record.status;
    const orderId = record.id;

    // Check if status actually changed (if old_record exists)
    if (payload.old_record && payload.old_record.status === newStatus) {
      return new Response(JSON.stringify({ message: "Status unchanged, ignoring." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 3. Fetch user FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from('user_tokens')
      .select('fcm_token')
      .eq('user_id', userId);

    if (tokensError) throw tokensError;

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No FCM tokens found for user." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 4. Determine Notification Content based on status
    let title = 'تحديث الطلب';
    let body = `تم تحديث حالة طلبك #${orderId}`;

    switch (newStatus.toLowerCase()) {
      case 'pending': 
        title = 'طلب جديد 🆕'; 
        body = 'تم استلام طلبك وهو قيد المراجعة الآن. سنقوم بتأكيده قريباً!'; 
        break;
      case 'accepted': 
        title = 'تم قبول الطلب ✅'; 
        body = 'رائع! تم قبول طلبك وجاري البدء في تحضيره.'; 
        break;
      case 'preparing': 
        title = 'جاري التحضير 👨‍🍳'; 
        body = 'طلبك الآن في الفرن! نجهزه لك بكل حب.'; 
        break;
      case 'ready': 
        title = 'الطلب جاهز 🍕'; 
        body = 'طلبك ساخن وجاهز الآن! بانتظار استلامك أو تسليمه للمندوب.'; 
        break;
      case 'delivering': 
        title = 'جاري التوصيل 🛵'; 
        body = 'طلبك في الطريق إليك! استعد لاستلامه قريباً.'; 
        break;
      case 'completed': 
        title = 'تم التسليم 🎉'; 
        body = 'بالهناء والشفاء! نتمنى أن تستمتع بوجبتك من بيتزا لمياء.'; 
        break;
      case 'cancelled': 
        title = 'تم إلغاء الطلب ❌'; 
        body = 'نأسف، تم إلغاء طلبك. نتمنى خدمتك في المرة القادمة.'; 
        break;
      case 'rejected': 
        title = 'عذراً، تعذر قبول الطلب 🚫'; 
        body = 'نعتذر منك، لم نتمكن من قبول طلبك في الوقت الحالي. يرجى التواصل معنا للمزيد من التفاصيل.'; 
        break;
      default:
        title = 'تحديث الطلب';
        body = `تم تحديث حالة طلبك إلى: ${newStatus}`;
    }

    // 5. Setup Firebase Credentials from ENV
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL');
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKey) {
      throw new Error("Firebase Service Account variables are missing from ENV.");
    }

    // 6. Get OAuth2 Access Token for FCM v1
    const accessToken = await getAccessToken(clientEmail, privateKey);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // 7. Send Push Notifications to all retrieved tokens
    const sendPromises = tokens.map(async (tokenRow) => {
      const token = tokenRow.fcm_token;
      
      const messagePayload = {
        message: {
          token: token,
          notification: { title, body },
          data: {
            order_id: String(orderId),
            status: newStatus,
            click_action: "FLUTTER_NOTIFICATION_CLICK"
          },
        }
      };

      const res = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(messagePayload),
      });

      if (!res.ok) {
        const errorData = await res.json();
        console.error(`Failed to send FCM to token ${token}:`, errorData);
        // If token is highly invalid/unregistered, you could delete it from Supabase here
      } else {
        console.log(`Successfully sent FCM to token ${token}`);
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ message: "Notifications dispatched successfully!" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Error Processing Webhook:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
