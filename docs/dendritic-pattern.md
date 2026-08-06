# The Dendritic Pattern for Nix Configurations

> A working document for this repository. It explains the dendritic pattern,
> how it relates to our current NixOS + home-manager flake, and what adopting it
> would look like.

## Sources

- **mightyiam/dendritic** — the original definition of the pattern.
  <https://github.com/mightyiam/dendritic>
- **vimjoyer, "Dendritic"** — a minimal flake-parts example with `import-tree`.
  <https://www.vimjoyer.com/nix/dendritic>
- **vimjoyer, "Dendritic Home Manager"** — extending the pattern to combine a
  NixOS system and a standalone home-manager configuration.
  <https://www.vimjoyer.com/nix/dendritic-home-manager>
- **vimjoyer, "Flake Dendritic"** — the same flake skeleton shown in the previous
  pages, collected as a single template.
  <https://www.vimjoyer.com/nix/flake-dendritic/flake>
- **vimjoyer, "Video 76 — Niri + wrapper modules"** — a practical demonstration
  of using the dendritic pattern to add a new window manager (Niri) without
  disturbing the existing setup, by composing wrapper modules and per-system
  packages.
  <https://www.vimjoyer.com/vid79-parts-wrapped>
- **nix-wrapper-modules** — the wrapper-modules project used in the Niri video.
  <https://birdeehub.github.io/nix-wrapper-modules/md/intro.html>

## 1. What the dendritic pattern is

The dendritic pattern is a way to organize Nix code that is built on the
*Nixpkgs module system*. The name comes from the idea that every file is a
branch in a tree: each file is a module, and modules are evaluated together in
one top-level configuration.

The key rule from the original author:

> "Every Nix file except for entry points such as `default.nix` and
> `flake.nix` is a module of the top-level configuration."  
> — mightyiam/dendritic

This means:

- The flake still has a top-level `flake.nix`.
- The top-level configuration is usually a `flake-parts` configuration.
- Every other `.nix` file is a module that is imported into that top-level
  configuration.
- Those modules then declare *lower-level* modules and configurations — NixOS
  configurations, home-manager configurations, nix-darwin configurations, or
  per-system packages — as option values.

### Why it is appealing

Most Nix configuration repos grow by adding more files, more imports, and more
levels of nesting. The result is often a web of `imports = [ ... ]` lists,
`specialArgs`, and `extraSpecialArgs` that are hard to trace. The dendritic
pattern tries to flatten this by making *everything* a top-level module, so
sharing values between files becomes a matter of reading from the top-level
`config` instead of threading arguments through special arguments.

## 2. The building blocks

### 2.1 The Nixpkgs module system

You already use this. NixOS, home-manager, and nix-darwin are all evaluated with
`lib.evalModules` (or wrappers like `lib.nixosSystem` and
`homeManagerConfiguration`). A module is a function that takes arguments like
`{ config, pkgs, lib, ... }:` and returns an attribute set of `options` and/or
`config`.

### 2.2 `deferredModule`

Normally, when you import a NixOS module, it is evaluated immediately as part of
a NixOS configuration. The `deferredModule` option type lets you store a module
as a value. Multiple modules can be *merged* under one option name. Later, a
NixOS or home-manager configuration can import that merged value.

Example from the dendritic documentation:

```nix
# modules/nixos/base.nix
{ lib, ... }: {
  options.nixos.base = lib.mkOption {
    type = lib.types.deferredModule;
  };
}

# modules/nixos/pc.nix
{ config, lib, ... }: {
  options.nixos.pc = lib.mkOption {
    type = lib.types.deferredModule;
  };
  config.nixos.pc = config.nixos.base;
}
```

This is the mechanism that makes the pattern work: top-level modules can
*produce* NixOS/home-manager modules, and other modules can *collect* them into
configurations.

### 2.3 flake-parts

`flake-parts` is a framework that evaluates a flake as a module system. It gives
you options like `flake.nixosConfigurations`, `flake.homeConfigurations`,
`perSystem.packages`, and so on. In the dendritic pattern, `flake-parts` is the
most common top-level configuration, but it is not required.

### 2.4 import-tree

`import-tree` (by `vic`) is a small library that walks a directory and imports
every `.nix` file as a module. This is what makes the "automatic importing"
claim practical. A typical entry point looks like:

```nix
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree ./modules);
}
```

With this, adding a new file under `modules/` automatically adds it to the
top-level configuration. This removes the need to edit `flake.nix` or maintain
long `imports` lists.

## 3. How the examples fit together

### 3.1 vimjoyer's minimal dendritic flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree ./modules);
}
```

This single `flake.nix` delegates all work to the modules in `modules/`.

```nix
# modules/nixos.nix
{ self, inputs, ... }: {
  flake.nixosConfigurations.HOSTNAME = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.HOSTNAMEModule
    ];
  };

  flake.nixosModules.HOSTNAMEModule = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.system}.default
    ];
  };
}
```

Notice that one top-level module both *defines* the NixOS configuration and
*defines* the reusable module that goes into it. The NixOS configuration is just
an option value (`flake.nixosConfigurations.HOSTNAME`), and the module is another
option value (`flake.nixosModules.HOSTNAMEModule`).

### 3.2 vimjoyer's NixOS + home-manager flake

This adds `home-manager` as a flake input and uses its `flakeModules` to add
home-manager options to `flake-parts`.

```nix
# modules/parts.nix
{ inputs, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
}
```

```nix
# modules/hosts/myMachine/configuration.nix
{ self, inputs, ... }: {
  flake.nixosConfigurations.HOSTNAME = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.HOSTNAMEModule
      self.nixosModules.myHomeManager
    ];
  };

  flake.nixosModules.HOSTNAMEModule = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.vim pkgs.firefox ];
    users.users.USERNAME = { isNormalUser = true; shell = pkgs.fish; };
    home-manager.users.USERNAME = self.homeModules.USERNAMEModule;
  };
}
```

```nix
# modules/hosts/myMachine/home.nix
{ self, inputs, ... }: {
  flake.homeConfigurations.USERNAME =
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      modules = [
        self.homeModules.USERNAMEModule
        { home.username = "USERNAME"; home.homeDirectory = "/home/USERNAME"; }
      ];
    };

  flake.homeModules.USERNAMEModule = { pkgs, ... }: {
    programs.bash.enable = true;
    home.packages = [ pkgs.hello ];
    home.stateVersion = "24.11";
  };
}
```

Important observations:

- `flake.homeModules.USERNAMEModule` is defined once and reused in both the
  standalone `homeConfigurations` and the NixOS `home-manager.users.USERNAME`
  import.
- The home-manager module is a *deferred* module: it is not evaluated until it
  is imported into a home-manager configuration.
- The top-level modules are the place where systems and users are wired together.

### 3.3 vimjoyer's Niri example (Video 76)

This is the practical payoff. The goal is to add a new window manager, Niri, to
an existing NixOS system without breaking it. The pattern allows the change to
be isolated in a feature module while the host configuration opts into it.

```nix
# modules/features/niri.nix
{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];
        binds = {
          "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
        };
      };
    };
  };
}
```

```nix
# modules/hosts/myMachine/configuration.nix
{ self, inputs, ... }: {
  flake.nixosModules.myMachineConfiguration = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
    ];
    # ...
  };
}
```

The wrapper-modules library provides a way to wrap a package (Niri) with a
generated configuration file. The dendritic pattern keeps the wrapper package
(`myNiri`) and the NixOS module that enables it in one feature file. The host
configuration imports the NixOS module when it wants that feature.

## 4. How this compares to our current repository

Our current repository is a simpler, more traditional flake.

### Current layout

```
flake.nix              # entry point, defines NixOS + home configs
vars.nix               # shared values, passed via specialArgs
hosts/
  nixos/
    configuration.nix  # imports NixOS modules
    hardware-configuration.nix
modules/nixos/
  base.nix
  desktop.nix
  packages.nix
  tailscale.nix
home/
  default.nix          # imports home modules
  packages.nix
  shell.nix
  git.nix
  ssh.nix
  kitty.nix
  opencode.nix
  neovim/
    default.nix
    init.lua
```

### Current `flake.nix`

```nix
{
  outputs = { self, nixpkgs, home-manager, ... }:
    let
      vars = import ./vars.nix;
      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit vars; };
        modules = [ ./home ];
      };
      mkNixOS = host: system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit vars; };
        modules = [ ./hosts/${host}/configuration.nix ];
      };
    in {
      formatter = ...;
      nixosConfigurations.nixos = mkNixOS "nixos" "x86_64-linux";
      homeConfigurations = {
        eric = mkHome "x86_64-linux";
        eric-darwin = mkHome "aarch64-darwin";
      };
    };
}
```

### Current `home/default.nix`

```nix
{
  imports = [
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./shell.nix
    ./neovim
    ./kitty.nix
    ./opencode.nix
  ];
  # ...
}
```

This already works, but it is not dendritic. The differences are:

| Aspect | Current repo | Dendritic pattern |
|--------|-------------|-------------------|
| Entry point | `flake.nix` does the wiring | `flake.nix` only sets up `flake-parts` + `import-tree` |
| Imports | Manual `imports` lists in `home/default.nix` and `hosts/nixos/configuration.nix` | Automatic via `import-tree` |
| Sharing values | `vars.nix` passed via `specialArgs`/`extraSpecialArgs` | `vars` is an option in the top-level config; any module reads `config.vars` |
| Modules | `modules/nixos/*.nix` are direct NixOS modules | `modules/nixos/*.nix` are *top-level* modules that produce NixOS modules via `deferredModule` options |
| Hosts | `hosts/nixos/configuration.nix` imports system modules | A top-level module declares the NixOS configuration and the modules it uses |
| Home-manager | `home/default.nix` is a direct home-manager module | `homeModules.eric` is a deferred module reused in NixOS and standalone configs |

## 5. What adopting the dendritic pattern would look like here

This is a proposed migration, not a committed change. It shows the shape of the
repository if we adopted the pattern.

### Step 1 — add flake inputs

We would replace `home-manager` as a direct input with `flake-parts`,
`import-tree`, and `home-manager` (still used for its `flakeModules`). We could
also keep `nixpkgs` on `nixos-26.05`.

### Step 2 — flatten `flake.nix`

```nix
{
  description = "Eric's system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree ./modules);
}
```

### Step 3 — add a `modules/systems.nix` or `modules/parts.nix`

```nix
{ inputs, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [ "x86_64-linux" "aarch64-darwin" ];
}
```

### Step 4 — turn `vars.nix` into a top-level option

```nix
# modules/vars.nix
{ lib, ... }: {
  options.vars = lib.mkOption {
    type = lib.types.attrs;
    default = {
      fullName = "Eric Baukhages";
      userName = "eric";
      # ...
    };
  };
}
```

Now any module can read `config.vars.userName` instead of needing `vars` as a
function argument.

### Step 5 — convert NixOS modules to deferred modules

Move `modules/nixos/*.nix` to `modules/features/nixos-*.nix` and make each one
produce a `flake.nixosModules.<name>` value.

For example:

```nix
# modules/features/nixos-desktop.nix
{ lib, ... }: {
  options.nixosModules.desktop = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
  };

  config.nixosModules.desktop = { config, pkgs, ... }: {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    # ... everything from modules/nixos/desktop.nix ...
  };
}
```

Or, more concisely, skip the option declaration and rely on flake-parts' own
`flake.nixosModules` option:

```nix
# modules/features/nixos-desktop.nix
{ ... }: {
  flake.nixosModules.desktop = { config, pkgs, ... }: {
    services.xserver.enable = true;
    # ...
  };
}
```

The second form is more idiomatic for flake-parts. The first form is closer to
the pure "dendritic" option-declaration style.

### Step 6 — convert the home configuration to a deferred module

```nix
# modules/home/eric.nix
{ self, ... }: {
  flake.homeModules.eric = { config, pkgs, lib, ... }:
    let isDarwin = pkgs.stdenv.isDarwin;
    in {
      home.username = config.vars.userName;   # or keep the vars arg
      home.homeDirectory = if isDarwin then "/Users/eric" else "/home/eric";
      home.stateVersion = "26.05";

      imports = [
        self.homeModules.ericPackages
        self.homeModules.ericShell
        self.homeModules.ericNeovim
        # ...
      ];

      home.sessionVariables.SSH_AUTH_SOCK =
        "${config.home.homeDirectory}/.1password/agent.sock";

      programs.home-manager.enable = true;
      xdg.enable = true;
      # ...
    };

  flake.homeConfigurations.eric =
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
      modules = [ self.homeModules.eric ];
    };

  flake.homeConfigurations.eric-darwin =
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages."aarch64-darwin";
      modules = [ self.homeModules.eric ];
    };
}
```

Each sub-module (`packages`, `shell`, etc.) would also be defined as
`flake.homeModules.ericPackages`, `flake.homeModules.ericShell`, and so on.

### Step 7 — define the NixOS host

```nix
# modules/hosts/nixos/default.nix
{ self, inputs, ... }: {
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.nixosConfig
    ];
  };

  flake.nixosModules.nixosConfig = { config, pkgs, ... }: {
    imports = [
      ./hardware-configuration.nix   # still a raw NixOS module
      self.nixosModules.base
      self.nixosModules.desktop
      self.nixosModules.packages
      self.nixosModules.tailscale
      self.nixosModules.homeManager  # enables the home-manager NixOS module
    ];

    home-manager.users.eric = self.homeModules.eric;
  };
}
```

Note: the hardware configuration would still be a plain NixOS module. It is one
of the natural exceptions to the pattern.

## 6. Benefits we would gain

1. **Fewer `imports` lists to maintain.** `import-tree` adds new files
   automatically. Adding a new feature is a matter of creating a file, not
   editing three lists.

2. **Reusable home-manager modules.** Today, the home configuration is defined
   once for standalone use and imported into NixOS via `home-manager.users.eric
   = import ./home;`. In the dendritic pattern, the same module is referenced as
   `self.homeModules.eric` in both places, making the intent clearer.

3. **Feature-based file paths.** A file like `modules/features/niri.nix` groups
   the NixOS module, the package override, and the wrapper configuration for one
   feature. This matches the design philosophy of organizing by capability rather
   than by layer.

4. **Easier experimentation.** The Niri example shows that a new feature can be
   written as a self-contained module and then opted into by a host. If the
   experiment fails, reverting it is one line in the host's `imports`.

5. **Clearer sharing of values.** `vars` would become a top-level option. Any
   module could read it without needing `specialArgs` or `extraSpecialArgs`. This
   removes one indirection layer.

6. **One mental model for everything.** Every file is a module. There is no
   separate "this file is a NixOS module, that file is a home-manager module, that
   file is a helper function" taxonomy.

## 7. Costs and risks

1. **It is another abstraction layer.** `flake-parts` and `import-tree` are
   additional tools to learn. If Nix itself already feels hard, adding two more
   concepts may not be a relief.

2. **The module system is subtle.** `deferredModule` merging, option
   declarations, and the difference between a top-level module and a lower-level
   module are real concepts. Debugging a mis-merged deferred module is harder than
   debugging a missing import.

3. **Automatic importing can hide mistakes.** `import-tree` will import every
   `.nix` file. A file that is accidentally included will be evaluated. There are
   exceptions for this, but it requires discipline.

4. **Current structure is small enough that the benefits are modest.** We have
   one host, one user, and a handful of modules. The dendritic pattern pays off
   most when there are multiple hosts, multiple users, or many feature modules.

5. **Existing `home/default.nix` imports are simple but not dendritic.** The
   home module currently contains a mix of concerns (GNOME dconf, session
   variables, imports). Splitting it into many small `flake.homeModules.*` files
   would be more files and more indirection.

6. **Tooling and evaluation order.** `nix flake check` and `just check` will
   evaluate more of the flake because `flake-parts` exposes more outputs. This is
   usually fine, but it can surface issues that were hidden before.

7. **Backward compatibility.** We have working `just home`, `just home-darwin`,
  and `just rebuild` recipes. A migration would change the flake outputs, so the
  `justfile` and the README would need updates.

## 8. How to decide

The dendritic pattern is a good fit if:

- We plan to add more hosts (a second NixOS machine, a Darwin host via
  nix-darwin, a work laptop, etc.).
- We plan to add more "features" that combine NixOS, packages, and
  home-manager configuration, such as a tiling window manager, a development
  environment, or a secrets-management setup.
- We want to stop threading `vars` and shared packages through
  `specialArgs`/`extraSpecialArgs`.
- We are comfortable learning `flake-parts` and `import-tree`.

It is probably not worth the cost if:

- The current one-host, one-user setup is the long-term state.
- The immediate priority is learning Nix itself, not learning another framework.
- We want to keep the flake as small and explicit as possible.

## 9. A minimal first step

If we want to try the pattern without a full migration, a small experiment would
be:

1. Add a new feature module, for example `modules/features/niri.nix`, in the
   dendritic style.
2. Do **not** switch the whole flake to `flake-parts` yet.
3. In the existing `flake.nix`, expose the new feature as a NixOS module and a
   package output, manually.
4. Import the NixOS module from `hosts/nixos/configuration.nix`.
5. Evaluate whether the file-by-feature organization is worth it.

This gives us the *organizational* benefit of the dendritic pattern for one
feature without the framework change.

A second, slightly larger step would be to migrate only the home-manager
configuration to use `flake.homeModules.eric`, keeping the existing `flake.nix`
style. This would let us experience the deferred-module concept in a smaller
surface area.

## 10. Glossary

- **Top-level module** — a module evaluated by the outermost `flake-parts`
  (or `lib.evalModules`) configuration. In the dendritic pattern, almost every
  file is a top-level module.
- **Lower-level module** — a NixOS, home-manager, or nix-darwin module that is
  stored as a value in the top-level configuration and later imported into a
  lower-level system evaluation.
- **deferredModule** — a Nixpkgs option type that holds a module as a value and
  allows merging of multiple modules.
- **flake-parts** — a framework for writing flakes as module-system
  configurations.
- **import-tree** — a helper that recursively imports every `.nix` file in a
  directory as a module.
- **specialArgs / extraSpecialArgs** — arguments passed to NixOS or home-manager
  evaluations. The dendritic pattern tries to minimize their use by putting
  shared values in the top-level config instead.

## 11. Open questions

- Do we want to keep `vars.nix` as a simple imported attrset, or do we want to
  expose it as a top-level option?
- Should we adopt `flake-parts` + `import-tree` fully, or just borrow the
  file-by-feature organization?
- How many hosts do we expect to have in the next year? Two or more strongly
  favors the dendritic pattern.
- Is the Niri/window-manager experiment something we want to pursue? If so, the
  dendritic pattern is a natural way to package it.
- Do we want to use nix-darwin for the macOS side? The pattern makes that easier
  because nix-darwin configurations can be lower-level outputs alongside NixOS
  and home-manager.
