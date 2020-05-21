# language-versions

This app will let you scan a user or organization for all .ruby-version, .node-version, and .tool-versions

## Running

* See Configs for what values

### Standalone

```
export CLIENT_ID=
export CLIENT_SECRET=
bundle install
bundle exec puma
```

### Docker

`docker run -e CLIENT_ID= -e CLIENT_SECRET= halkeye/language-versions:master` (or use a tag - https://hub.docker.com/r/halkeye/language-versions/tags)

## Config (Environment Variables)

* APP_ENV - Set to something other than `development`, probably `production`

Either use a github oauth app (https://github.com/settings/developers), and have everyone sign in with thier own credentials

* CLIENT_ID = OAuth App Client ID
* CLIENT_SECRET = OAuth App Client Secret

OR a github token

* CLIENT_TOKEN - Token from https://github.com/settings/tokens with scopes of `read:org, repo`

## License

MIT

