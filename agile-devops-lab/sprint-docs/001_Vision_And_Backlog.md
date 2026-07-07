### Product Vision (quizme)

To make learning fun, accessible, and engaging by providing a simple flashcard quiz app that helps people expand their general knowledge and cultural awareness through quick, interactive quizzes they can enjoy anytime.

### Backlog

1. As a user, I want to start a quiz with one tap so I can begin answering questions quickly (**SP-1**)

   **Acceptance criteria**
   - There is a quick start button on home page
   - Quiz begins immediately after tapping the quickstart

   Priority: 100

2. As a user, I want to be able to answer either multiple questions or True/false questions so that I can test my knowledge (**SP-3**)

   **Acceptance criteria**
   - Each question has either 4 options OR a true and false
   - Only one option can be selected
   - User submits after selection

   Priority: 100

3. As a user, I want to be able to get instant feedback so that I can know whether my answers are correct or not (**SP-3**)

   **Acceptance criteria**
   - Correct Answer is highlighted in green or any appropriate color
   - If wrong answer was selected, it should be highlighted in red or any appropriate color

   Priority: 100

4. As a user, I want to be able to move to the next question so that I can proceed with the quiz (**SP-2**)

   **Acceptance criteria**
   - Next question button shows up after instant feedback
   - Clicking on next question gives you another question

   Priority: 100

5. As a user, I want to be able to see the scores of my quiz as I progress through each of them. (**SP-2**)

   **Acceptance criteria**
   - An immediate visible section of how many questions I attempted, how many I got correct, how many wrongs, and a percentage correction
   - Score updates after any submission

   Priority: 80

6. As a user, I want to be able to choose the category of quiz so that I get questions related to only that category (**SP-5**)

   **Acceptance criteria**
   - A list of available categories to choose from
   - Clicking on any category gives question related to that category

   Priority: 40

7. As a user, I want to be able to finish a quiz so that I dont end up in a continuous stream of question answering (**SP-2**)

   **Acceptance criteria**
   - A finish quiz button should be visible to end a quiz
   - Finish quiz should end the quiz session
   - There should be a prompt to start a new quiz

   Priority: 70

8. As a user, I want to be able to see my general performance and categorical performance after I finish a quiz so that I can know which categories I am more strongly suited for (**SP-3**)

   **Acceptance criteria**
   - Upon clicking the finish quiz, I should see general statistics of my quiz performance as well as a category breakdown.

   Priority: 60

**Note**:
- (SP-X) corresponds to the story point value. X is the actual value assigned
- Priority scores range from 0 to a 100, with a 100 being the highest priority

---

### Definition of Done

A user story is considered done when all of the following are true:
- All acceptance criteria for the story are met
- The feature renders correctly in the browser without console errors
- At least one unit test covers the core logic of the story
- Code is committed with a meaningful commit message
- The CI pipeline passes (build + tests)
- The feature is usable without breaking any previously delivered story
