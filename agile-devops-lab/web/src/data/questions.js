/**
 * QuizMe question bank
 *
 * Each question:
 *   - id:           unique identifier
 *   - type:         'multiple-choice' | 'true-false'
 *   - categories:   array of topic areas (used in Sprint 2)
 *   - question:     question text
 *   - options:      answer strings (4 for MC, 2 for T/F)
 *   - correctIndex: index of the correct answer in options
 */

export const questions = [
  // Multiple Choice
  {
    id: 1,
    type: 'multiple-choice',
    categories: ['geography'],
    question: 'What is the largest country in Africa by land area?',
    options: ['Democratic Republic of Congo', 'Sudan', 'Algeria', 'Libya'],
    correctIndex: 2,
  },
  {
    id: 2,
    type: 'multiple-choice',
    categories: ['history'],
    question: 'Which African country was never colonised by a European power?',
    options: ['Ghana', 'Ethiopia', 'Senegal', 'Kenya'],
    correctIndex: 1,
  },
  {
    id: 3,
    type: 'multiple-choice',
    categories: ['geography'],
    question: 'What is the longest river in Africa?',
    options: ['Congo River', 'Niger River', 'Zambezi River', 'Nile River'],
    correctIndex: 3,
  },
  {
    id: 4,
    type: 'multiple-choice',
    categories: ['culture'],
    question: 'Which African country is the origin of the Afrobeats music genre?',
    options: ['Ghana', 'South Africa', 'Nigeria', 'Cameroon'],
    correctIndex: 2,
  },
  {
    id: 5,
    type: 'multiple-choice',
    categories: ['history'],
    question: 'In what year did Ghana gain independence from Britain?',
    options: ['1957', '1960', '1963', '1948'],
    correctIndex: 0,
  },
  {
    id: 6,
    type: 'multiple-choice',
    categories: ['geography'],
    question: 'Which African city is the most populous?',
    options: ['Johannesburg', 'Nairobi', 'Cairo', 'Lagos'],
    correctIndex: 3,
  },
  {
    id: 7,
    type: 'multiple-choice',
    categories: ['science', 'geography'],
    question: 'Which African country is home to the Serengeti National Park?',
    options: ['Kenya', 'Tanzania', 'Uganda', 'Rwanda'],
    correctIndex: 1,
  },
  {
    id: 8,
    type: 'multiple-choice',
    categories: ['history'],
    question: 'Who was the first President of Ghana?',
    options: ['Kofi Annan', 'Jerry Rawlings', 'Kwame Nkrumah', 'John Kufuor'],
    correctIndex: 2,
  },
  {
    id: 9,
    type: 'multiple-choice',
    categories: ['culture'],
    question: 'What does "Ubuntu" mean in African philosophy?',
    options: [
      'I am because of who we all are',
      'The land belongs to the people',
      'Respect your elders',
      'Work brings honour',
    ],
    correctIndex: 0,
  },
  {
    id: 10,
    type: 'multiple-choice',
    categories: ['geography'],
    question: 'Which is the highest mountain in Africa?',
    options: ['Mount Kenya', 'Mount Kilimanjaro', 'Ras Dashen', 'Mount Meru'],
    correctIndex: 1,
  },
  {
    id: 11,
    type: 'multiple-choice',
    categories: ['history', 'culture'],
    question: 'The ancient Egyptian writing system is known as what?',
    options: ['Cuneiform', 'Hieroglyphics', 'Linear A', 'Proto-Sinaitic'],
    correctIndex: 1,
  },
  {
    id: 12,
    type: 'multiple-choice',
    categories: ['culture'],
    question: 'Kente cloth originates from which African country?',
    options: ['Nigeria', 'Senegal', 'Ghana', 'Côte d\'Ivoire'],
    correctIndex: 2,
  },

  // True / False
  {
    id: 13,
    type: 'true-false',
    categories: ['geography'],
    question: 'Africa is the world\'s largest continent by land area.',
    options: ['True', 'False'],
    correctIndex: 1,
  },
  {
    id: 14,
    type: 'true-false',
    categories: ['history'],
    question: 'Nelson Mandela served 27 years in prison before becoming President of South Africa.',
    options: ['True', 'False'],
    correctIndex: 0,
  },
  {
    id: 15,
    type: 'true-false',
    categories: ['science', 'geography'],
    question: 'The Sahara Desert is the largest hot desert in the world.',
    options: ['True', 'False'],
    correctIndex: 0,
  },
  {
    id: 16,
    type: 'true-false',
    categories: ['culture'],
    question: 'Swahili is the most widely spoken language in West Africa.',
    options: ['True', 'False'],
    correctIndex: 1,
  },
  {
    id: 17,
    type: 'true-false',
    categories: ['history'],
    question: 'The African Union has its headquarters in Addis Ababa, Ethiopia.',
    options: ['True', 'False'],
    correctIndex: 0,
  },
  {
    id: 18,
    type: 'true-false',
    categories: ['geography'],
    question: 'Lake Victoria is the largest lake in Africa.',
    options: ['True', 'False'],
    correctIndex: 0,
  },
  {
    id: 19,
    type: 'true-false',
    categories: ['culture', 'history'],
    question: 'The Great Pyramids of Giza were built by enslaved people.',
    options: ['True', 'False'],
    correctIndex: 1,
  },
  {
    id: 20,
    type: 'true-false',
    categories: ['science'],
    question: 'Africa is home to more than 25% of the world\'s bird species.',
    options: ['True', 'False'],
    correctIndex: 0,
  },
];

/**
 * Returns a shuffled copy of the questions array.
 */
export function getShuffledQuestions() {
  return [...questions].sort(() => Math.random() - 0.5);
}

/**
 * Checks whether a selected index is the correct answer.
 * @param {object} question
 * @param {number} selectedIndex
 * @returns {boolean}
 */
export function isCorrectAnswer(question, selectedIndex) {
  return question.correctIndex === selectedIndex;
}
