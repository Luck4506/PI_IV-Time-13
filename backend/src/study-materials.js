// Autoria de Lucas Soares Gonçalves RA 25009467
function readGraphMaterial(row) {
  const { id, titulo, versao, titulosBlocos, textosBlocos } = row;
  const version = Number(versao);

  if (typeof titulo !== 'string' || !titulo.trim() ||
    !Number.isSafeInteger(version) || version < 1 ||
    !Array.isArray(titulosBlocos) || !Array.isArray(textosBlocos) ||
    titulosBlocos.length !== textosBlocos.length || !textosBlocos.length) return null;

  const blocos = textosBlocos.map((texto, index) => ({ titulo: titulosBlocos[index], texto }));
  if (!blocos.every(bloco => typeof bloco.titulo === 'string' && bloco.titulo.trim() &&
    typeof bloco.texto === 'string' && bloco.texto.trim())) return null;

  return { _id: id, titulo, versao: version, blocos };
}

export async function loadStudyMaterials(databases, ids) {
  const materials = new Map();
  if (!ids.length) return materials;

  const result = await databases.query(`
    MATCH (m:MaterialEstudo)
    WHERE m.id IN $ids AND m.publicado = true
    RETURN m { .id, .titulo, .versao, .titulosBlocos, .textosBlocos } AS material
  `, { ids });

  for (const record of result.records) {
    const material = readGraphMaterial(record.get('material'));
    if (material) materials.set(material._id, material);
  }

  // Bancos antigos ainda podem ter materiais disponíveis apenas no MongoDB.
  const missing = ids.filter(id => !materials.has(id));
  if (missing.length) {
    const legacy = await databases.db.collection('materiais_conteudo').find(
      { _id: { $in: missing }, publicado: true },
      { projection: { titulo: 1, versao: 1, blocos: 1 } },
    ).toArray();
    for (const material of legacy) materials.set(material._id, material);
  }

  return materials;
}
