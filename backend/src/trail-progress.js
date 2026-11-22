// Autoria de Lucas Soares Gonçalves RA 25009467
import { ApiError } from './api-error.js';
import { loadStudyMaterials } from './study-materials.js';
import { contentStages } from './trail-planning.js';

export async function stagesWithProgress(databases, trail, stages = contentStages(trail), materials) {
  if (!stages.length) return stages;

  const stageIds = stages.map(stage => stage.id);
  const [materialsById, progress] = await Promise.all([
    materials ?? loadStudyMaterials(databases, stageIds),
    databases.db.collection('progresso_conteudos').find({
      usuarioId: trail.usuarioId,
      trilhaId: trail._id,
    }).toArray(),
  ]);

  const progressById = new Map(progress.map(read => [read.conteudoId, read]));

  return stages.map(stage => {
    const material = materialsById.get(stage.id);
    const read = progressById.get(stage.id);
    const published = hasMaterial(material);
    const readCurrentVersion = published && Boolean(read) && read.materialVersao === material.versao;
    const readDone = stage.status === 'concluida' || readCurrentVersion;

    return {
      ...stage,
      materialPublicado: published,
      leituraConcluida: readDone,
      materialTitulo: published ? material.titulo : 'Material em preparação',
      praticaDisponivel: stage.status !== 'bloqueada' && (!published || readDone),
    };
  });
}

export function hasMaterial(material) {
  return Boolean(material?.blocos?.length);
}

export async function recordReading(databases, trail, material) {
  if (!hasMaterial(material)) {
    throw new ApiError(409, 'Este conteúdo ainda não possui material publicado. A prática já está disponível.');
  }

  const progress = databases.db.collection('progresso_conteudos');
  const filter = {
    usuarioId: trail.usuarioId,
    trilhaId: trail._id,
    conteudoId: material._id,
  };
  const now = new Date();

  // Uma leitura antiga pode chegar depois da nova. Guardar a maior versão
  // evita bloquear de novo a prática de quem já leu o material atualizado.
  const update = {
    $max: { materialVersao: material.versao, leituraConcluidaEm: now },
    $setOnInsert: { criadoEm: now },
  };

  try {
    await progress.updateOne(filter, update, { upsert: true });
  } catch (error) {
    if (error.code !== 11000) throw error;

    // O índice único preserva uma leitura por aluno, trilha e conteúdo.
    await progress.updateOne(filter, update);
  }
}
