import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function POST(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    const subscription = await request.json();

    const user = await prisma.user.findUnique({ where: { id: session.id } });
    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found. Please log in again.' }), { status: 404 });
    }

    await prisma.user.update({
      where: { id: session.id },
      data: { push_subscription: JSON.stringify(subscription) }
    });

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to save subscription' }), { status: 500 });
  }
}
