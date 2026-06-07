import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

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

    return new Response(JSON.stringify(messages), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Fetch messages error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { content, receiver_id } = await request.json();

    if (!content) {
      return new Response(JSON.stringify({ error: 'Content is required' }), { status: 400, headers: corsHeaders });
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

    return new Response(JSON.stringify(newMessage), { status: 201, headers: corsHeaders });
  } catch (error) {
    console.error('Send message error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
