/*
 * This is a trigger to populate a default Task whenever a new opportunity is created.
 *
 * @Author: System Partners
 */
trigger createTaskAfterOppCreation on Opportunity (after insert) {
    OpportunityUtility.createTaskAfterOppCreation(Trigger.New);
}