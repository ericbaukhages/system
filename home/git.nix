{ vars, ... }:

{
  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      key = vars.sshPublicKey;
    };

    settings = {
      user = {
        name = vars.fullName;
        email = vars.userEmail;
      };
      init.defaultBranch = "main";
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "~/.config/git/allowed_signers";
      };
    };
  };

  home.file.".config/git/allowed_signers".text = "${vars.userEmail} ${vars.sshPublicKey}\n";
}
