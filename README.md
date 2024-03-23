# edge-app-alarm-threshold-notifier
Edge app with notification on meta data from functions.

Triggers when functions are over or under a threshold value.

Monitors any function within the installation haveing any of these metadata set

`alarm_over`
`alarm_under`
`alarm_on`
`alarm_not`

If the value goes above `alarm_max` or below `alarm_min` a notification is sent. No repetative notification is sent unless a value witnin the normal range is received. When `alarm_on` is used an alarm is sent when the value is exactly `alarm_on` and `alarm_not` on everything but `alarm_not`.

Please observe that you specify when the alarm is sent, not what is normal value. Some examples.

When the value normally is below 20 and an alarm should be sent on higher valies use:

`alarm_over: 20` (above 20 an alarm vill be sent (20 os ok, 20.1 is alarm)

When `alarm_over` and `alarm_under` is used at the same time it works like this.

`alarm_over: 10` and `alarm_under: 20` will send alarm between 10 and 20 (exklusive)

`alarm_under: 10` and `alarm_over: 20` will send alarm when not between 10 and 20.


Example notification message.

```
Installation: {{.installation.Name}}
Value: {{.payload.value}}
Device: {{.payload.device.meta.name}}
Function: {{.payload.func.meta.name}}
Trigger: {{.payload.trigger}} (over, under, on, not)
Threshold: {{.payload.threshold}}
```
.payload.func  and payload.device are the complete function and device objects. 

```
The funcion "{{.payload.func.meta.name}}" on the devie "{{.payload.device.meta.name}}" in installation "{{.installation.Name}}" is triggering an Alarm.

Current value is {{.payload.value}} and that is {{.payload.trigger}} {{.payload.threshold}}
```
That can be formatted in any way. If you want to translate the trigger it is is also possible using conditional statements in the template.
