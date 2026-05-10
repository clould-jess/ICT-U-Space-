import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

async function requireAdmin() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) return null;
  const session = JSON.parse(sessionCookie.value);
  return session.role === 'ADMIN' ? session : null;
}

export async function POST(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { name, capacity, features, building_block } = await request.json();
    const hall = await prisma.hall.create({ data: { name, capacity, features, building_block } });
    return new Response(JSON.stringify(hall), { status: 201 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to create hall' }), { status: 500 });
  }
}

export async function PUT(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { id, capacity, name, features, building_block } = await request.json();
    const data = {};
    if (capacity !== undefined) data.capacity = parseInt(capacity);
    if (name !== undefined) data.name = name;
    if (features !== undefined) data.features = features;
    if (building_block !== undefined) data.building_block = building_block;

    const hall = await prisma.hall.update({ where: { id }, data });
    return new Response(JSON.stringify(hall), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to update hall' }), { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { id } = await request.json();
    await prisma.hall.delete({ where: { id } });
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to delete hall' }), { status: 500 });
  }
}
