# edge-app-alarm-threshold-notifier

Edge app with notification on meta data from functions. Using this app the thresholds is set only in metadata and can differ from function to function. What messages that should be sent out is configured in the app but then you can forget about it and only set thresholds on functions.

Monitors any function within the installation having any of these metadata set

`alarm_over` Trigger alarm when value over threshold\
`alarm_under` Trigger alarm when value under threshold\
`alarm_on` Trigger alarm when value is the same as the threshold\
`alarm_not` Trigger alarm when the value is anything but the threshold\

If the value goes above `alarm_max` or below `alarm_min` a notification is sent. No repetitive notification is sent unless a value within the normal range is received. This is useful for things like temperature, air pollution, illuminance and other analog values.

When `alarm_on` is used an alarm is sent when the value is exactly `alarm_on` and `alarm_not` on everything but `alarm_not`. This is useful for things with states. E.g. door sensors, motion detectors, switches, and different kinds of alarm and states.

Please observe that you specify when the alarm is sent, not what is normal value. Some examples.

When the value normally is below 20 and an alarm should be sent on higher values use:

`alarm_over: 20` (above 20 an alarm will be sent (20 is ok, 20.1 is alarm)

When `alarm_over` and `alarm_under` is used at the same time it works like this.

`alarm_over: 10` and `alarm_under: 20` will send alarm between 10 and 20 (exclusive)

`alarm_under: 10` and `alarm_over: 20` will send alarm when not between 10 and 20.

Notification is sent through standard IoT Open Notifications, Below are some examples of messages.

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
The function "{{.payload.func.meta.name}}" on the device "{{.payload.device.meta.name}}" in installation "{{.installation.Name}}" is triggering an Alarm.

Current value is {{.payload.value}} and that is {{.payload.trigger}} {{.payload.threshold}}
```
That can be formatted in any way. If you want to translate the trigger it is is also possible using conditional statements in the template.
