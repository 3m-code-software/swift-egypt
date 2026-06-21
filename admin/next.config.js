const { withSentryConfig } = require('@sentry/nextjs')
const withNextIntl = require('next-intl/plugin')()

module.exports = withSentryConfig(
  withNextIntl({}),
  {
    org: process.env.SENTRY_ORG,
    project: process.env.SENTRY_PROJECT,
    authToken: process.env.SENTRY_AUTH_TOKEN,
    silent: true,
    widenClientFileUpload: true,
    telemetry: false,
  },
)
