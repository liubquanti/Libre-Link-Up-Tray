# LibreLinkUp HTTP-Dump

This document describes the HTTP communication of LibreLinkUp which functions as follower app to receive cgm data. Some data in the responses were masked.

## Context

This dump was created on an android device with LibreLinkUp app. Capturing was done with HttpToolkit over adb.

## API Url

The global api url is `https://api.libreview.io`. If you are placed in europe you can use `https://api-eu.libreview.io` instead.

## Headers

The following list includes general purpose headers but also specific ones which are required to get correct responses:

### General purpose

```
'accept-encoding': 'gzip'
'cache-control': 'no-cache'
'connection': 'Keep-Alive'
'content-type': 'application/json'
```

### Specific

The following headers are **required** and needs to be setted to get correct responses. There might be alternative values which are not known.

```
'product': 'llu.android'
'version': '4.12.0',
```

## Request Flow

To get cgm data from the api it is required to fire at least *three* requests:

1. Login and retrieve JWT Token
2. Get connections of patients to get `patientId`
3. Retrieve cgm data of specific `patient`

### Login

This request expects credentials and will return a JWT Token which is required to call auth-needed endpoints.

**Endpoint**  POST /llu/auth/login

**Request Body**

```
{
  "email": "your-libre-email@provider.com",
  "password": "$yOurVerySecretPasSw0rd!"
}
```

**Response**

```
{
  "status": 0,
  "data": {
    "user": {
      "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "firstName": "John",
      "lastName": "Doe",
      "email": "your-libre-email@provider.com",
      "country": "DE",
      "uiLanguage": "de-DE",
      "communicationLanguage": "de-DE",
      "accountType": "pat",
      "uom": "1",
      "dateFormat": "2",
      "timeFormat": "2",
      "emailDay": [
        1
      ],
      "system": {
        "messages": {
          "firstUsePhoenix": 1652399492,
          "firstUsePhoenixReportsDataMerged": 1652399492,
          "lluGettingStartedBanner": 1652399555,
          "lluNewFeatureModal": 1652399526,
          "lluOnboarding": 1652399536,
          "lvWebPostRelease": "3.9.47"
        }
      },
      "details": {},
      "created": 1652399492,
      "lastLogin": 1653140180,
      "programs": {},
      "dateOfBirth": 627609600,
      "practices": {},
      "devices": {},
      "consents": {
        "llu": {
          "policyAccept": 1652399485,
          "touAccept": 1652399485
        }
      }
    },
    "messages": {
      "unread": 0
    },
    "notifications": {
      "unresolved": 0
    },
    "authTicket": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZlZGFjNDk2LWQyNGUtMTFlYy04ZTVkLTAyNDJhYzExMDAwMiIsImZpcnN0TmFtZSI6IkhhbGltZSBTZWxjdWsiLCJsYXN0TmFtZSI6Iktla2VjIiwiY291bnRyeSI6IkRFIiwicmVnaW9uIjoiZXUiLCJyb2xlIjoicGF0aWVudCIsInVuaXRzIjoxLCJwcmFjdGljZXMiOltdLCJjIjoxLCJzIjoibGx1LmFuZHJvaWQiLCJleHAiOjE2Njg2OTIzNTh9.MdEzdJ3NrpYS4WVAcuy87Gxzk7EJFHzCtei-y7_XXXX",
      "expires": 1668692358,
      "duration": 15552000000
    },
    "invitations": [
      "xxxxxxxxx"
    ]
  }
}
```

The JWT Token is present in `data.authTicket.token` and is valid for nearly 6 month which is quite long. This is extremly long and actually you cannot invalidate this token why you should not share it with anyone.

For the next requests you have to set this token in the headers:

```
'authorization': Bearer [YOUR_JWT_TOKEN]
```

### Get connections

To be able to retrieve cgm data you have to determine the `patientId` of the person who is sharing his data with you.

**Endpoint**   GET /llu/connections

**Response**

```
{
  "status": 0,
  "data": [
    {
      "id": "xxxxx",
      "patientId": "xxxxxxx",
      "country": "DE",
      "status": 2,
      "firstName": "John",
      "lastName": "Doe",
      "targetLow": 70,
      "targetHigh": 130,
      "uom": 1,
      "sensor": {
        "deviceId": "",
        "sn": "xxxxx",
        "a": 1652400270,
        "w": 60,
        "pt": 4
      },
      "alarmRules": {
        "c": true,
        "h": {
          "on": true,
          "th": 130,
          "thmm": 7.2,
          "d": 1440,
          "f": 0.1
        },
        "f": {
          "th": 55,
          "thmm": 3,
          "d": 30,
          "tl": 10,
          "tlmm": 0.6
        },
        "l": {
          "on": true,
          "th": 70,
          "thmm": 3.9,
          "d": 1440,
          "tl": 10,
          "tlmm": 0.6
        },
        "nd": {
          "i": 20,
          "r": 5,
          "l": 6
        },
        "p": 5,
        "r": 5,
        "std": {}
      },
      "glucoseMeasurement": {
        "FactoryTimestamp": "5/21/2022 1:38:50 PM",
        "Timestamp": "5/21/2022 3:38:50 PM",
        "type": 1,
        "ValueInMgPerDl": 91,
        "TrendArrow": 3,
        "TrendMessage": null,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 91,
        "isHigh": false,
        "isLow": false
      },
      "glucoseItem": {
        "FactoryTimestamp": "5/21/2022 1:38:50 PM",
        "Timestamp": "5/21/2022 3:38:50 PM",
        "type": 1,
        "ValueInMgPerDl": 91,
        "TrendArrow": 3,
        "TrendMessage": null,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 91,
        "isHigh": false,
        "isLow": false
      },
      "glucoseAlarm": null,
      "patientDevice": {
        "did": "2d97357e-d250-11ec-b409-0242ac110004",
        "dtid": 40068,
        "v": "3.3.1",
        "ll": 65,
        "hl": 130,
        "u": 1653016896,
        "fixedLowAlarmValues": {
          "mgdl": 60,
          "mmoll": 3.3
        },
        "alarms": false
      },
      "created": 1652399545
    }
  ],
  "ticket": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZlZGFjNDk2LWQyNGUtMTFlYy04ZTVkLTAyNDJhYzExMDAwMiIsImZpcnN0TmFtZSI6IkhhbGltZSBTZWxjdWsiLCJsYXN0TmFtZSI6Iktla2VjIiwiY291bnRyeSI6IkRFIiwicmVnaW9uIjoiZXUiLCJyb2xlIjoicGF0aWVudCIsInVuaXRzIjoxLCJwcmFjdGljZXMiOltdLCJjIjoxLCJzIjoibGx1LmFuZHJvaWQiLCJleHAiOjE2Njg2OTIzNTh9.MdEzdJ3NrpYS4WVAcuy87Gxzk7EJFHzCtei-y7_XXXX",
    "expires": 1668692358,
    "duration": 15552000000
  }
}
```

The `data`part includes all persons who are sharing their data with you. To retrieve cgm data you need `data[0].patientId`.

### Get cgm data

Now both prerequirements (JWT Token and Patient ID) are met and you can retrieve the cgm data.

**Endpoint**  GET /llu/connections/`{patientId}`/graph

**Response**

```
{
  "status": 0,
  "data": {
    "connection": {
      "id": "xxxxxxx",
      "patientId": "xxxxxxx",
      "country": "DE",
      "status": 2,
      "firstName": "John",
      "lastName": "Doe",
      "targetLow": 70,
      "targetHigh": 130,
      "uom": 1,
      "sensor": {
        "deviceId": "",
        "sn": "XXXXXXXXXX",
        "a": 1652400270,
        "w": 60,
        "pt": 4
      },
      "alarmRules": {
        "c": true,
        "h": {
          "on": true,
          "th": 130,
          "thmm": 7.2,
          "d": 1440,
          "f": 0.1
        },
        "f": {
          "th": 55,
          "thmm": 3,
          "d": 30,
          "tl": 10,
          "tlmm": 0.6
        },
        "l": {
          "on": true,
          "th": 70,
          "thmm": 3.9,
          "d": 1440,
          "tl": 10,
          "tlmm": 0.6
        },
        "nd": {
          "i": 20,
          "r": 5,
          "l": 6
        },
        "p": 5,
        "r": 5,
        "std": {}
      },
      "glucoseMeasurement": {
        "FactoryTimestamp": "5/21/2022 1:38:50 PM",
        "Timestamp": "5/21/2022 3:38:50 PM",
        "type": 1,
        "ValueInMgPerDl": 91,
        "TrendArrow": 3,
        "TrendMessage": null,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 91,
        "isHigh": false,
        "isLow": false
      },
      "glucoseItem": {
        "FactoryTimestamp": "5/21/2022 1:38:50 PM",
        "Timestamp": "5/21/2022 3:38:50 PM",
        "type": 1,
        "ValueInMgPerDl": 91,
        "TrendArrow": 3,
        "TrendMessage": null,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 91,
        "isHigh": false,
        "isLow": false
      },
      "glucoseAlarm": null,
      "patientDevice": {
        "did": "xxxxxxx",
        "dtid": 40068,
        "v": "3.3.1",
        "ll": 65,
        "hl": 130,
        "u": 1653016896,
        "fixedLowAlarmValues": {
          "mgdl": 60,
          "mmoll": 3.3
        },
        "alarms": false
      },
      "created": 1652399545
    },
    "activeSensors": [
      {
        "sensor": {
          "deviceId": "xxxxxx",
          "sn": "xxxxx",
          "a": 1652400270,
          "w": 60,
          "pt": 4
        },
        "device": {
          "did": "xxxxxx",
          "dtid": 40068,
          "v": "3.3.1",
          "ll": 65,
          "hl": 130,
          "u": 1653016896,
          "fixedLowAlarmValues": {
            "mgdl": 60,
            "mmoll": 3.3
          },
          "alarms": false
        }
      },
      {
        "sensor": {
          "deviceId": "xxxxx",
          "sn": "xxxxxx",
          "a": 1652399154,
          "w": 60,
          "pt": 4
        },
        "device": {
          "did": "xxxxxxxxx",
          "dtid": 40068,
          "v": "3.3.1",
          "ll": 70,
          "hl": 250,
          "u": 1652399060,
          "fixedLowAlarmValues": {
            "mgdl": 60,
            "mmoll": 3.3
          },
          "alarms": false
        }
      },
      {
        "sensor": {
          "deviceId": "xxxxx",
          "sn": "xxxxx",
          "a": 1652391830,
          "w": 60,
          "pt": 4
        },
        "device": {
          "did": "xxxxx",
          "dtid": 40068,
          "v": "3.3.1",
          "ll": 70,
          "hl": 250,
          "u": 1652396851,
          "fixedLowAlarmValues": {
            "mgdl": 60,
            "mmoll": 3.3
          },
          "alarms": false
        }
      }
    ],
    "graphData": [
      {
        "FactoryTimestamp": "5/21/2022 1:39:50 AM",
        "Timestamp": "5/21/2022 3:39:50 AM",
        "type": 0,
        "ValueInMgPerDl": 117,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 117,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 1:44:51 AM",
        "Timestamp": "5/21/2022 3:44:51 AM",
        "type": 0,
        "ValueInMgPerDl": 115,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 115,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 1:49:50 AM",
        "Timestamp": "5/21/2022 3:49:50 AM",
        "type": 0,
        "ValueInMgPerDl": 115,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 115,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 1:54:51 AM",
        "Timestamp": "5/21/2022 3:54:51 AM",
        "type": 0,
        "ValueInMgPerDl": 116,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 116,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 1:59:50 AM",
        "Timestamp": "5/21/2022 3:59:50 AM",
        "type": 0,
        "ValueInMgPerDl": 116,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 116,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 2:04:50 AM",
        "Timestamp": "5/21/2022 4:04:50 AM",
        "type": 0,
        "ValueInMgPerDl": 118,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 118,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 2:09:50 AM",
        "Timestamp": "5/21/2022 4:09:50 AM",
        "type": 0,
        "ValueInMgPerDl": 118,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 118,
        "isHigh": false,
        "isLow": false
      },
      {
        "FactoryTimestamp": "5/21/2022 2:14:51 AM",
        "Timestamp": "5/21/2022 4:14:51 AM",
        "type": 0,
        "ValueInMgPerDl": 115,
        "MeasurementColor": 1,
        "GlucoseUnits": 1,
        "Value": 115,
        "isHigh": false,
        "isLow": false
      }
    ]
  },
  "ticket": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZlZGFjNDk2LWQyNGUtMTFlYy04ZTVkLTAyNDJhYzExMDAwMiIsImZpcnN0TmFtZSI6IkhhbGltZSBTZWxjdWsiLCJsYXN0TmFtZSI6Iktla2VjIiwiY291bnRyeSI6IkRFIiwicmVnaW9uIjoiZXUiLCJyb2xlIjoicGF0aWVudCIsInVuaXRzIjoxLCJwcmFjdGljZXMiOltdLCJjIjoxLCJzIjoibGx1LmFuZHJvaWQiLCJleHAiOjE2Njg2OTIzNTl9.LK8Ejr2IDKGM7oiObVYMHC8HV2bPcv6obt7UiEFXXXX",
    "expires": 1668692359,
    "duration": 15552000000
  }
}
```

The last measurement is present in `glucoseMeasurement`:

```
{
  "FactoryTimestamp": "5/21/2022 1:38:50 PM",
  "Timestamp": "5/21/2022 3:38:50 PM",
  "type": 1,
  "ValueInMgPerDl": 91,
  "TrendArrow": 3,
  "TrendMessage": null,
  "MeasurementColor": 1,
  "GlucoseUnits": 1,
  "Value": 91,
  "isHigh": false,
  "isLow": false
}
```

Instead you can find historical measurements in `graphData`. The data has the same shape as above.

## Contact

Selcuk Kekec

E-mail: [khskekec@gmail.com](khskekec@gmail.com)
