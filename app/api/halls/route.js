import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const halls = await prisma.hall.findMany();
    return new Response(JSON.stringify(halls), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch halls' }), { status: 500 });
  }
}
