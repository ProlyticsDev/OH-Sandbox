/*
 * A Before trigger for updating activity date whenever due date is change on Task.
 *
 * @Author: System Partners
 */
trigger updateActivityDate on Task (before insert, before update) {
    if (Trigger.IsUpdate)
        TaskUtil.updateActivityDate(Trigger.New, Trigger.oldMap);
    else
        TaskUtil.updateActivityDate(Trigger.New);
}