import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const subscription = await request.json();

    const user = await prisma.user.findUnique({ where: { id: session.id } });
    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found. Please log in again.' }), { status: 404, headers: corsHeaders });
    }

    await prisma.user.update({
      where: { id: session.id },
      data: { push_subscription: JSON.stringify(subscription) }
    });

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to save subscription' }), { status: 500, headers: corsHeaders });
  }
}
