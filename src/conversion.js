console.log('Loading function');
const { queue, role, destination } = process.env;
const aws = require('aws-sdk');

const s3 = new aws.S3({ apiVersion: '2006-03-01' });
const mediaConvert = new aws.MediaConvert({
  apiVersion: '2017-08-29'
});

async function createJob(source) {

  const { Endpoints } = await mediaConvert.describeEndpoints({MaxResults: 0}).promise();
  //If someone can tell me how to update the endpoint of the existing client that would be great
  const jobClient = new aws.MediaConvert({
    apiVersion: '2017-08-29',
    endpoint: Endpoints[0].Url
  });

  const params = {
    "Queue": queue,
    "Role": role,
    "Settings": {
      "TimecodeConfig": {
        "Source": "ZEROBASED"
      },
      "OutputGroups": [
        {
          "CustomName": "CMAF Widescreen",
          "Name": "CMAF",
          "Outputs": [
            {
              "ContainerSettings": {
                "Container": "CMFC"
              },
              "VideoDescription": {
                "Width": 1280,
                "Height": 720,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "FramerateControl": "INITIALIZE_FROM_SOURCE",
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION",
                    "QualityTuningLevel": "MULTI_PASS_HQ"
                  }
                }
              }
            },
            {
              "ContainerSettings": {
                "Container": "CMFC"
              },
              "AudioDescriptions": [
                {
                  "AudioSourceName": "Audio Selector 1",
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ]
            }
          ],
          "OutputGroupSettings": {
            "Type": "CMAF_GROUP_SETTINGS",
            "CmafGroupSettings": {
              "SegmentLength": 10,
              "Destination": `s3://${destination}/hls-widescreen/`,
              "FragmentLength": 2
            }
          },
          "AutomatedEncodingSettings": {
            "AbrSettings": {
              "MaxRenditions": 5,
              "MaxAbrBitrate": 3000000
            }
          }
        },
        {
          "CustomName": "CMAF Vertical",
          "Name": "CMAF",
          "Outputs": [
            {
              "ContainerSettings": {
                "Container": "CMFC"
              },
              "VideoDescription": {
                "Width": 720,
                "Height": 1280,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "FramerateControl": "INITIALIZE_FROM_SOURCE",
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION",
                    "QualityTuningLevel": "MULTI_PASS_HQ"
                  }
                }
              }
            },
            {
              "ContainerSettings": {
                "Container": "CMFC"
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ]
            }
          ],
          "OutputGroupSettings": {
            "Type": "CMAF_GROUP_SETTINGS",
            "CmafGroupSettings": {
              "SegmentLength": 10,
              "Destination": `s3://${destination}/hls-vertical/`,
              "FragmentLength": 2
            }
          },
          "AutomatedEncodingSettings": {
            "AbrSettings": {
              "MaxRenditions": 5,
              "MaxAbrBitrate": 3000000
            }
          }
        },
        {
          "CustomName": "File Widescreen",
          "Name": "File Group",
          "Outputs": [
            {
              "ContainerSettings": {
                "Container": "WEBM"
              },
              "VideoDescription": {
                "Width": 1280,
                "Height": 720,
                "CodecSettings": {
                  "Codec": "VP9",
                  "Vp9Settings": {
                    "RateControlMode": "VBR",
                    "Bitrate": 1800000
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "OPUS",
                    "OpusSettings": {}
                  }
                }
              ],
              "Extension": "webm",
              "NameModifier": "1280x720"
            },
            {
              "ContainerSettings": {
                "Container": "MP4",
                "Mp4Settings": {}
              },
              "VideoDescription": {
                "Width": 1280,
                "Height": 720,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "MaxBitrate": 1800000,
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION"
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ],
              "Extension": "mp4",
              "NameModifier": "1280x720"
            },
            {
              "ContainerSettings": {
                "Container": "WEBM"
              },
              "VideoDescription": {
                "Width": 480,
                "Height": 360,
                "CodecSettings": {
                  "Codec": "VP9",
                  "Vp9Settings": {
                    "RateControlMode": "VBR",
                    "Bitrate": 280000
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "OPUS",
                    "OpusSettings": {}
                  }
                }
              ],
              "Extension": "webm",
              "NameModifier": "480x360"
            },
            {
              "ContainerSettings": {
                "Container": "MP4",
                "Mp4Settings": {}
              },
              "VideoDescription": {
                "Width": 480,
                "Height": 360,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "MaxBitrate": 280000,
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION"
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ],
              "Extension": "mp4",
              "NameModifier": "480x360"
            }
          ],
          "OutputGroupSettings": {
            "Type": "FILE_GROUP_SETTINGS",
            "FileGroupSettings": {
              "Destination": `s3://${destination}/widescreen/`
            }
          }
        },
        {
          "CustomName": "File Vertical",
          "Name": "File Group",
          "Outputs": [
            {
              "ContainerSettings": {
                "Container": "WEBM"
              },
              "VideoDescription": {
                "Width": 720,
                "Height": 1280,
                "CodecSettings": {
                  "Codec": "VP9",
                  "Vp9Settings": {
                    "RateControlMode": "VBR",
                    "Bitrate": 1800000
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "OPUS",
                    "OpusSettings": {}
                  }
                }
              ],
              "Extension": "webm",
              "NameModifier": "720x1280"
            },
            {
              "ContainerSettings": {
                "Container": "MP4",
                "Mp4Settings": {}
              },
              "VideoDescription": {
                "Width": 720,
                "Height": 1280,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "MaxBitrate": 1800000,
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION"
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ],
              "Extension": "mp4",
              "NameModifier": "720x1280"
            },
            {
              "ContainerSettings": {
                "Container": "WEBM"
              },
              "VideoDescription": {
                "Width": 360,
                "Height": 480,
                "CodecSettings": {
                  "Codec": "VP9",
                  "Vp9Settings": {
                    "RateControlMode": "VBR",
                    "Bitrate": 280000
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "OPUS",
                    "OpusSettings": {}
                  }
                }
              ],
              "Extension": "webm",
              "NameModifier": "360x480"
            },
            {
              "ContainerSettings": {
                "Container": "MP4",
                "Mp4Settings": {}
              },
              "VideoDescription": {
                "Width": 360,
                "Height": 480,
                "CodecSettings": {
                  "Codec": "H_264",
                  "H264Settings": {
                    "MaxBitrate": 280000,
                    "RateControlMode": "QVBR",
                    "SceneChangeDetect": "TRANSITION_DETECTION"
                  }
                }
              },
              "AudioDescriptions": [
                {
                  "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                      "Bitrate": 96000,
                      "CodingMode": "CODING_MODE_2_0",
                      "SampleRate": 48000
                    }
                  }
                }
              ],
              "Extension": "mp4",
              "NameModifier": "360x480"
            }
          ],
          "OutputGroupSettings": {
            "Type": "FILE_GROUP_SETTINGS",
            "FileGroupSettings": {
              "Destination": `s3://${destination}/vertical/`
            }
          }
        }
      ],
      "Inputs": [
        {
          "AudioSelectors": {
            "Audio Selector 1": {
              "DefaultSelection": "DEFAULT"
            }
          },
          "VideoSelector": {},
          "TimecodeSource": "ZEROBASED",
          "FileInput": source
        }
      ]
    },
    "AccelerationSettings": {
      "Mode": "DISABLED"
    },
    "Priority": 0,
    "HopDestinations": []
  }

  return await jobClient.createJob(params).promise();
}

exports.handler = async (event, context) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  const bucket = event.Records[0].s3.bucket.name;
  const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
  const source = `s3://${bucket}/${key}`;
  const params = {
    Bucket: bucket,
    Key: key
  };

  try {
    const metadata = await s3.headObject(params).promise();

    if (metadata.ContentType && metadata.ContentType === 'video/mp4') {

      const response = await createJob(source);
      console.log(response);
      if (response.Job.Status === 'SUBMITTED') {
        return response;
      } else {
        throw new Error('Job submission failed. Check the logs and try again.');
      }
    } else {
      throw new Error(`${key} is not a video/mp4 MIME type.`)
    }

  } catch (err) {
    console.log(err);
    const message = `Error getting object ${key} from bucket ${bucket}. Make sure they exist and your bucket is in the same region as this function.`;
    console.log(message);
    throw new Error(message);
  }
};
