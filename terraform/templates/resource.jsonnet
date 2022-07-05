{
  sshConnection(host, user, privateKey):: {
    connection: {
      type: 'ssh',
      host: host,
      user: user,
      private_key: privateKey,
      agent: true,
    },
  },
}
