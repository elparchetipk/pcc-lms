// MongoDB Schema for Notifications and Flexible Data
// Version: 2025-08-08
// Description: Document schemas for notification service and flexible content

// =============================================================================
// NOTIFICATION COLLECTIONS
// =============================================================================

// Notification Queue Collection
db.createCollection('notification_queue', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: [
        'userId',
        'type',
        'title',
        'message',
        'priority',
        'status',
        'createdAt',
      ],
      properties: {
        _id: { bsonType: 'objectId' },
        userId: { bsonType: 'string' },
        templateId: { bsonType: 'string' },
        type: {
          bsonType: 'string',
          enum: ['email', 'push', 'sms', 'in_app', 'webhook'],
        },
        title: { bsonType: 'string', maxLength: 255 },
        message: { bsonType: 'string' },
        priority: {
          bsonType: 'string',
          enum: ['low', 'normal', 'high', 'urgent'],
        },
        status: {
          bsonType: 'string',
          enum: [
            'pending',
            'processing',
            'sent',
            'delivered',
            'read',
            'failed',
            'cancelled',
          ],
        },
        recipientInfo: {
          bsonType: 'object',
          properties: {
            email: { bsonType: 'string' },
            phone: { bsonType: 'string' },
            deviceTokens: { bsonType: 'array', items: { bsonType: 'string' } },
          },
        },
        metadata: { bsonType: 'object' },
        scheduledFor: { bsonType: 'date' },
        attemptCount: { bsonType: 'int', minimum: 0 },
        lastAttemptAt: { bsonType: 'date' },
        sentAt: { bsonType: 'date' },
        deliveredAt: { bsonType: 'date' },
        readAt: { bsonType: 'date' },
        errorMessage: { bsonType: 'string' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' },
      },
    },
  },
});

// Notification Delivery Logs
db.createCollection('notification_logs', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['notificationId', 'userId', 'type', 'status', 'timestamp'],
      properties: {
        _id: { bsonType: 'objectId' },
        notificationId: { bsonType: 'string' },
        userId: { bsonType: 'string' },
        type: {
          bsonType: 'string',
          enum: ['email', 'push', 'sms', 'in_app', 'webhook'],
        },
        status: {
          bsonType: 'string',
          enum: [
            'sent',
            'delivered',
            'read',
            'failed',
            'bounced',
            'unsubscribed',
          ],
        },
        providerResponse: { bsonType: 'object' },
        errorCode: { bsonType: 'string' },
        errorMessage: { bsonType: 'string' },
        deliveryTime: { bsonType: 'int' }, // milliseconds
        timestamp: { bsonType: 'date' },
      },
    },
  },
});

// =============================================================================
// FLEXIBLE CONTENT COLLECTIONS
// =============================================================================

// Dynamic Course Content (for complex interactive content)
db.createCollection('course_content', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: [
        'courseId',
        'lessonId',
        'contentType',
        'data',
        'version',
        'createdAt',
      ],
      properties: {
        _id: { bsonType: 'objectId' },
        courseId: { bsonType: 'string' },
        lessonId: { bsonType: 'string' },
        contentType: {
          bsonType: 'string',
          enum: [
            'interactive_exercise',
            'code_playground',
            '3d_model',
            'simulation',
            'custom_widget',
          ],
        },
        data: { bsonType: 'object' }, // Flexible content data
        metadata: {
          bsonType: 'object',
          properties: {
            title: { bsonType: 'string' },
            description: { bsonType: 'string' },
            tags: { bsonType: 'array', items: { bsonType: 'string' } },
            difficulty: {
              bsonType: 'string',
              enum: ['beginner', 'intermediate', 'advanced'],
            },
            estimatedTime: { bsonType: 'int' }, // minutes
          },
        },
        version: { bsonType: 'string' },
        isPublished: { bsonType: 'bool' },
        publishedAt: { bsonType: 'date' },
        createdBy: { bsonType: 'string' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' },
      },
    },
  },
});

// User-Generated Content (forums, discussions, comments)
db.createCollection('user_content', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['userId', 'contentType', 'content', 'createdAt'],
      properties: {
        _id: { bsonType: 'objectId' },
        userId: { bsonType: 'string' },
        courseId: { bsonType: 'string' },
        lessonId: { bsonType: 'string' },
        parentId: { bsonType: 'string' }, // For threaded discussions
        contentType: {
          bsonType: 'string',
          enum: [
            'discussion_post',
            'comment',
            'question',
            'answer',
            'review',
            'note',
          ],
        },
        content: { bsonType: 'string' },
        attachments: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              fileId: { bsonType: 'string' },
              fileName: { bsonType: 'string' },
              fileType: { bsonType: 'string' },
              fileSize: { bsonType: 'long' },
            },
          },
        },
        metadata: {
          bsonType: 'object',
          properties: {
            isAnonymous: { bsonType: 'bool' },
            isPinned: { bsonType: 'bool' },
            isFeatured: { bsonType: 'bool' },
            tags: { bsonType: 'array', items: { bsonType: 'string' } },
          },
        },
        interactions: {
          bsonType: 'object',
          properties: {
            likes: { bsonType: 'int', minimum: 0 },
            dislikes: { bsonType: 'int', minimum: 0 },
            replies: { bsonType: 'int', minimum: 0 },
            views: { bsonType: 'int', minimum: 0 },
          },
        },
        moderation: {
          bsonType: 'object',
          properties: {
            status: {
              bsonType: 'string',
              enum: ['pending', 'approved', 'rejected', 'flagged'],
            },
            moderatedBy: { bsonType: 'string' },
            moderatedAt: { bsonType: 'date' },
            reason: { bsonType: 'string' },
          },
        },
        isEdited: { bsonType: 'bool' },
        editedAt: { bsonType: 'date' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' },
      },
    },
  },
});

// =============================================================================
// REAL-TIME FEATURES
// =============================================================================

// Live Chat Sessions (for live courses or support)
db.createCollection('chat_sessions', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sessionId', 'type', 'participants', 'status', 'createdAt'],
      properties: {
        _id: { bsonType: 'objectId' },
        sessionId: { bsonType: 'string' },
        type: {
          bsonType: 'string',
          enum: ['course_live', 'support', 'study_group', 'office_hours'],
        },
        courseId: { bsonType: 'string' },
        lessonId: { bsonType: 'string' },
        hostId: { bsonType: 'string' },
        participants: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              userId: { bsonType: 'string' },
              role: {
                bsonType: 'string',
                enum: ['host', 'moderator', 'participant'],
              },
              joinedAt: { bsonType: 'date' },
              leftAt: { bsonType: 'date' },
              isActive: { bsonType: 'bool' },
            },
          },
        },
        status: {
          bsonType: 'string',
          enum: ['scheduled', 'active', 'ended', 'cancelled'],
        },
        metadata: {
          bsonType: 'object',
          properties: {
            title: { bsonType: 'string' },
            description: { bsonType: 'string' },
            maxParticipants: { bsonType: 'int' },
            isRecorded: { bsonType: 'bool' },
            recordingUrl: { bsonType: 'string' },
          },
        },
        scheduledStart: { bsonType: 'date' },
        actualStart: { bsonType: 'date' },
        endedAt: { bsonType: 'date' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' },
      },
    },
  },
});

// Chat Messages
db.createCollection('chat_messages', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sessionId', 'userId', 'message', 'timestamp'],
      properties: {
        _id: { bsonType: 'objectId' },
        sessionId: { bsonType: 'string' },
        userId: { bsonType: 'string' },
        messageType: {
          bsonType: 'string',
          enum: ['text', 'emoji', 'file', 'poll', 'announcement', 'system'],
        },
        message: { bsonType: 'string' },
        attachments: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              type: { bsonType: 'string', enum: ['image', 'file', 'link'] },
              url: { bsonType: 'string' },
              name: { bsonType: 'string' },
              size: { bsonType: 'long' },
            },
          },
        },
        reactions: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              userId: { bsonType: 'string' },
              emoji: { bsonType: 'string' },
              timestamp: { bsonType: 'date' },
            },
          },
        },
        replyTo: { bsonType: 'string' }, // Message ID
        isEdited: { bsonType: 'bool' },
        editedAt: { bsonType: 'date' },
        isDeleted: { bsonType: 'bool' },
        deletedAt: { bsonType: 'date' },
        timestamp: { bsonType: 'date' },
      },
    },
  },
});

// =============================================================================
// SYSTEM LOGS AND EVENTS
// =============================================================================

// Application Events and Audit Trail
db.createCollection('system_events', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['eventType', 'source', 'data', 'timestamp'],
      properties: {
        _id: { bsonType: 'objectId' },
        eventType: { bsonType: 'string' },
        source: { bsonType: 'string' }, // Service name
        userId: { bsonType: 'string' },
        entityType: { bsonType: 'string' },
        entityId: { bsonType: 'string' },
        action: { bsonType: 'string' },
        data: { bsonType: 'object' },
        metadata: {
          bsonType: 'object',
          properties: {
            ipAddress: { bsonType: 'string' },
            userAgent: { bsonType: 'string' },
            correlationId: { bsonType: 'string' },
            sessionId: { bsonType: 'string' },
          },
        },
        timestamp: { bsonType: 'date' },
      },
    },
  },
});

// =============================================================================
// INDEXES FOR PERFORMANCE
// =============================================================================

// Notification indexes
db.notification_queue.createIndex({ userId: 1 });
db.notification_queue.createIndex({ status: 1 });
db.notification_queue.createIndex({ scheduledFor: 1 });
db.notification_queue.createIndex({ createdAt: 1 });
db.notification_queue.createIndex({ type: 1, status: 1 });

db.notification_logs.createIndex({ notificationId: 1 });
db.notification_logs.createIndex({ userId: 1 });
db.notification_logs.createIndex({ timestamp: -1 });

// Content indexes
db.course_content.createIndex({ courseId: 1, lessonId: 1 });
db.course_content.createIndex({ contentType: 1 });
db.course_content.createIndex({ isPublished: 1 });

db.user_content.createIndex({ userId: 1 });
db.user_content.createIndex({ courseId: 1, contentType: 1 });
db.user_content.createIndex({ parentId: 1 });
db.user_content.createIndex({ createdAt: -1 });

// Chat indexes
db.chat_sessions.createIndex({ sessionId: 1 });
db.chat_sessions.createIndex({ courseId: 1, status: 1 });
db.chat_sessions.createIndex({ hostId: 1 });

db.chat_messages.createIndex({ sessionId: 1, timestamp: 1 });
db.chat_messages.createIndex({ userId: 1 });

// System events indexes
db.system_events.createIndex({ eventType: 1, timestamp: -1 });
db.system_events.createIndex({ userId: 1, timestamp: -1 });
db.system_events.createIndex({ entityType: 1, entityId: 1 });

// TTL indexes for cleanup
db.notification_logs.createIndex(
  { timestamp: 1 },
  { expireAfterSeconds: 7776000 }
); // 90 days
db.system_events.createIndex(
  { timestamp: 1 },
  { expireAfterSeconds: 15552000 }
); // 180 days
