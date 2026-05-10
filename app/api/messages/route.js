import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function GET(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    // Fetch messages where user is either sender or receiver
    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { sender_id: session.id },
          { receiver_id: session.id },
          { receiver_id: null } // broadcast messages
        ]
      },
      include: {
        sender: { select: { id: true, name: true, role: true } },
        receiver: { select: { id: true, name: true, role: true } }
      },
      orderBy: { created_at: 'asc' }
    });

    return new Response(JSON.stringify(messages), { status: 200 });
  } catch (error) {
    console.error('Fetch messages error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}

export async function POST(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    const { content, receiver_id } = await request.json();

    if (!content) {
      return new Response(JSON.stringify({ error: 'Content is required' }), { status: 400 });
    }

    const newMessage = await prisma.message.create({
      data: {
        content,
        sender_id: session.id,
        receiver_id: receiver_id || null
      },
      include: {
        sender: { select: { id: true, name: true, role: true } },
        receiver: { select: { id: true, name: true, role: true } }
      }
    });

    return new Response(JSON.stringify(newMessage), { status: 201 });
  } catch (error) {
    console.error('Send message error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
