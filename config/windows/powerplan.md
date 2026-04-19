
# Set Ultimate Performance power plan

create:
```
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
```

activate:
```
powercfg /setactive [OUTPUT of previous command]
```
# Power plans in Windows 7/8/10/11:

| Plan Name            | GUID                                 |
| -------------------- | ------------------------------------ |
| Balanced             | 381b4222-f694-41f0-9685-ff5bb260df2e |
| High Performance     | 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c |
| Power Saver          | a1841308-3541-4fab-bc81-f71556f20b4a |
| Ultimate Performance | e9a42b02-d5df-448d-aa00-03f14749eb61 |