part of '../../telas_estudante.dart';

class TopicProgressData {
  const TopicProgressData({
    required this.name,
    required this.schoolStage,
    required this.mastery,
    required this.accuracy,
    required this.questionsAnswered,
    required this.insight,
    required this.nextStep,
  });

  final String name;
  final String schoolStage;
  final double mastery;
  final int accuracy;
  final int questionsAnswered;
  final String insight;
  final String nextStep;
}

class SubjectProgressData {
  const SubjectProgressData({
    required this.name,
    required this.summary,
    required this.schoolStage,
    required this.mastery,
    required this.color,
    required this.icon,
    required this.topics,
  });

  final String name;
  final String summary;
  final String schoolStage;
  final double mastery;
  final Color color;
  final IconData icon;
  final List<TopicProgressData> topics;
}

abstract final class SubjectProfiles {
  static const mathematics = SubjectProgressData(
    name: 'Matemática',
    summary: 'Foco atual: equação do 2º grau',
    schoolStage: 'Fundamental II · Ensino Médio · Vestibulares',
    mastery: .61,
    color: AppColors.coral,
    icon: Icons.calculate_rounded,
    topics: [
      TopicProgressData(
        name: 'Equação do 2º grau',
        schoolStage: 'Ensino Médio',
        mastery: .38,
        accuracy: 41,
        questionsAnswered: 22,
        insight:
            'Dificuldade em identificar os coeficientes e aplicar Bhaskara.',
        nextStep: 'Mais questões guiadas e revisão de discriminante.',
      ),
      TopicProgressData(
        name: 'Geometria plana',
        schoolStage: 'Fundamental II',
        mastery: .57,
        accuracy: 59,
        questionsAnswered: 17,
        insight: 'Bom reconhecimento de figuras, com erros em cálculo de área.',
        nextStep: 'Revisar áreas de triângulos e quadriláteros.',
      ),
      TopicProgressData(
        name: 'Razão e proporção',
        schoolStage: 'Fundamental II',
        mastery: .72,
        accuracy: 76,
        questionsAnswered: 29,
        insight: 'Desempenho consistente em regra de três simples.',
        nextStep: 'Avançar para problemas com grandezas compostas.',
      ),
      TopicProgressData(
        name: 'Frações e porcentagem',
        schoolStage: 'Fundamental II',
        mastery: .81,
        accuracy: 85,
        questionsAnswered: 33,
        insight: 'Conteúdo consolidado nas últimas revisões.',
        nextStep: 'Manter apenas revisões espaçadas.',
      ),
      TopicProgressData(
        name: 'Função do 1º grau',
        schoolStage: 'Ensino Médio',
        mastery: .88,
        accuracy: 91,
        questionsAnswered: 36,
        insight: 'Ótimo domínio de gráficos, raízes e interpretação.',
        nextStep: 'Reduzir frequência e avançar para função quadrática.',
      ),
    ],
  );

  static const chemistry = SubjectProgressData(
    name: 'Química',
    summary: 'Prioridade: estequiometria e mol',
    schoolStage: 'Ensino Médio · Vestibulares',
    mastery: .56,
    color: AppColors.primary,
    icon: Icons.science_rounded,
    topics: [
      TopicProgressData(
        name: 'Estequiometria',
        schoolStage: 'Ensino Médio',
        mastery: .34,
        accuracy: 37,
        questionsAnswered: 19,
        insight: 'Erros ao relacionar proporções entre reagentes e produtos.',
        nextStep: 'Praticar relações molares com exemplos resolvidos.',
      ),
      TopicProgressData(
        name: 'Conceito de mol',
        schoolStage: 'Ensino Médio',
        mastery: .42,
        accuracy: 45,
        questionsAnswered: 24,
        insight: 'Dificuldade na conversão entre massa, mol e partículas.',
        nextStep: 'Reforçar massa molar e número de Avogadro.',
      ),
      TopicProgressData(
        name: 'Balanceamento químico',
        schoolStage: 'Ensino Médio',
        mastery: .58,
        accuracy: 61,
        questionsAnswered: 21,
        insight: 'Acerta equações simples, mas hesita em reações maiores.',
        nextStep: 'Praticar balanceamento por tentativa.',
      ),
      TopicProgressData(
        name: 'Ligações químicas',
        schoolStage: 'Ensino Médio',
        mastery: .76,
        accuracy: 79,
        questionsAnswered: 28,
        insight: 'Bom domínio das ligações iônicas e covalentes.',
        nextStep: 'Avançar para geometria molecular.',
      ),
      TopicProgressData(
        name: 'Misturas e separação',
        schoolStage: 'Fundamental II',
        mastery: .84,
        accuracy: 88,
        questionsAnswered: 25,
        insight: 'Conteúdo consolidado e aplicado corretamente.',
        nextStep: 'Manter revisões espaçadas.',
      ),
    ],
  );

  static const portuguese = SubjectProgressData(
    name: 'Português',
    summary: 'Interpretação está em alta',
    schoolStage: 'Fundamental II · Ensino Médio · Vestibulares',
    mastery: .71,
    color: AppColors.sky,
    icon: Icons.menu_book_rounded,
    topics: [
      TopicProgressData(
        name: 'Concordância verbal',
        schoolStage: 'Ensino Médio',
        mastery: .44,
        accuracy: 48,
        questionsAnswered: 20,
        insight: 'Erros em sujeitos compostos e expressões partitivas.',
        nextStep: 'Revisar regras e resolver questões contextualizadas.',
      ),
      TopicProgressData(
        name: 'Orações subordinadas',
        schoolStage: 'Ensino Médio',
        mastery: .53,
        accuracy: 56,
        questionsAnswered: 18,
        insight: 'Reconhece conectivos, mas confunde classificações.',
        nextStep: 'Praticar identificação da função sintática.',
      ),
      TopicProgressData(
        name: 'Funções da linguagem',
        schoolStage: 'Ensino Médio',
        mastery: .68,
        accuracy: 72,
        questionsAnswered: 26,
        insight: 'Boa leitura de intenção comunicativa.',
        nextStep: 'Avançar para gêneros textuais de vestibular.',
      ),
      TopicProgressData(
        name: 'Classes gramaticais',
        schoolStage: 'Fundamental II',
        mastery: .79,
        accuracy: 82,
        questionsAnswered: 31,
        insight: 'Distingue classes e seus usos no texto.',
        nextStep: 'Manter revisões espaçadas.',
      ),
      TopicProgressData(
        name: 'Interpretação de texto',
        schoolStage: 'Vestibulares',
        mastery: .86,
        accuracy: 89,
        questionsAnswered: 42,
        insight: 'Excelente identificação de tese e inferências.',
        nextStep: 'Aumentar a complexidade dos textos.',
      ),
    ],
  );

  static const biology = SubjectProgressData(
    name: 'Biologia',
    summary: 'Revisar genética e citologia',
    schoolStage: 'Fundamental II · Ensino Médio · Vestibulares',
    mastery: .66,
    color: AppColors.mint,
    icon: Icons.biotech_rounded,
    topics: [
      TopicProgressData(
        name: 'Genética mendeliana',
        schoolStage: 'Ensino Médio',
        mastery: .43,
        accuracy: 46,
        questionsAnswered: 23,
        insight: 'Dificuldade em cruzamentos e leitura de heredogramas.',
        nextStep: 'Praticar probabilidade e primeira lei de Mendel.',
      ),
      TopicProgressData(
        name: 'Citologia',
        schoolStage: 'Ensino Médio',
        mastery: .55,
        accuracy: 59,
        questionsAnswered: 27,
        insight: 'Confunde funções de algumas organelas celulares.',
        nextStep: 'Revisar organelas com mapa visual.',
      ),
      TopicProgressData(
        name: 'Fisiologia humana',
        schoolStage: 'Ensino Médio',
        mastery: .64,
        accuracy: 68,
        questionsAnswered: 25,
        insight: 'Bom entendimento geral dos sistemas.',
        nextStep: 'Conectar sistemas respiratório e circulatório.',
      ),
      TopicProgressData(
        name: 'Ecologia',
        schoolStage: 'Vestibulares',
        mastery: .81,
        accuracy: 84,
        questionsAnswered: 34,
        insight: 'Domina relações ecológicas e ciclos biogeoquímicos.',
        nextStep: 'Avançar para impactos ambientais.',
      ),
      TopicProgressData(
        name: 'Cadeias alimentares',
        schoolStage: 'Fundamental II',
        mastery: .87,
        accuracy: 91,
        questionsAnswered: 22,
        insight: 'Conteúdo consolidado.',
        nextStep: 'Manter apenas revisões espaçadas.',
      ),
    ],
  );

  static const physics = SubjectProgressData(
    name: 'Física',
    summary: 'Foco atual: eletricidade',
    schoolStage: 'Ensino Médio · Vestibulares',
    mastery: .59,
    color: AppColors.amber,
    icon: Icons.bolt_rounded,
    topics: [
      TopicProgressData(
        name: 'Eletricidade',
        schoolStage: 'Ensino Médio',
        mastery: .39,
        accuracy: 42,
        questionsAnswered: 21,
        insight: 'Dificuldade em associar tensão, corrente e resistência.',
        nextStep: 'Reforçar lei de Ohm e circuitos simples.',
      ),
      TopicProgressData(
        name: 'Cinemática',
        schoolStage: 'Ensino Médio',
        mastery: .51,
        accuracy: 54,
        questionsAnswered: 28,
        insight: 'Interpreta tabelas, mas erra gráficos de movimento.',
        nextStep: 'Praticar gráficos de posição e velocidade.',
      ),
      TopicProgressData(
        name: 'Dinâmica',
        schoolStage: 'Ensino Médio',
        mastery: .63,
        accuracy: 67,
        questionsAnswered: 24,
        insight: 'Aplica bem as leis de Newton em casos simples.',
        nextStep: 'Avançar para planos inclinados.',
      ),
      TopicProgressData(
        name: 'Óptica',
        schoolStage: 'Vestibulares',
        mastery: .74,
        accuracy: 78,
        questionsAnswered: 19,
        insight: 'Bom domínio de espelhos e reflexão.',
        nextStep: 'Avançar para lentes esféricas.',
      ),
    ],
  );

  static const history = SubjectProgressData(
    name: 'História',
    summary: 'Aprofundar Era Vargas',
    schoolStage: 'Fundamental II · Ensino Médio · Vestibulares',
    mastery: .69,
    color: Color(0xFF9B6AD6),
    icon: Icons.account_balance_rounded,
    topics: [
      TopicProgressData(
        name: 'Era Vargas',
        schoolStage: 'Ensino Médio',
        mastery: .52,
        accuracy: 55,
        questionsAnswered: 20,
        insight: 'Confunde fases políticas e medidas econômicas.',
        nextStep: 'Revisar linha do tempo de 1930 a 1945.',
      ),
      TopicProgressData(
        name: 'Ditadura militar',
        schoolStage: 'Ensino Médio',
        mastery: .63,
        accuracy: 67,
        questionsAnswered: 24,
        insight: 'Reconhece eventos, mas precisa conectá-los ao contexto.',
        nextStep: 'Trabalhar causas, atos institucionais e abertura.',
      ),
      TopicProgressData(
        name: 'Brasil República',
        schoolStage: 'Vestibulares',
        mastery: .76,
        accuracy: 79,
        questionsAnswered: 31,
        insight: 'Boa compreensão dos principais períodos.',
        nextStep: 'Resolver questões interdisciplinares.',
      ),
      TopicProgressData(
        name: 'Revolução Industrial',
        schoolStage: 'Fundamental II',
        mastery: .84,
        accuracy: 88,
        questionsAnswered: 25,
        insight: 'Conteúdo consolidado e contextualizado.',
        nextStep: 'Manter revisões espaçadas.',
      ),
    ],
  );

  static const all = [
    mathematics,
    chemistry,
    portuguese,
    biology,
    physics,
    history,
  ];
}
