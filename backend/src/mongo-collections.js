// Autoria de Lucas Soares Gonçalves RA 25009467
export async function ensureCollection(db, name, options) {
  const filter = { name };
  const existing = await db.listCollections(filter).next();
  if (existing) return existing;

  try {
    await db.createCollection(name, options);
    return null;
  } catch (error) {
    // Duas instâncias podem tentar criar a coleção na primeira inicialização.
    // O Mongo usa NamespaceExists (48) quando a outra já terminou.
    if (error.code !== 48) throw error;

    const createdByAnother = await db.listCollections(filter).next();
    if (!createdByAnother) throw error;
    return createdByAnother;
  }
}
