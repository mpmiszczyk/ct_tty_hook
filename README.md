Based purly on [MongooseIM tests](https://github.com/esl/ejabberd_tests/blob/master/src/ct_tty_hook.erl).

Adds reasonable tty error reporting in your tty.

## Usage

### ct_run

Simply add `-ct_hooks ct_tty_hook` flag to `ct_run`

### `*.spec` config file

Add `{ct_hooks, [ct_tty_hook]}.` to your `*.spec` configuration file.

### rebar

Extend your `ct_extra_params`  parameter with `"-ct_hooks ct_tty_hook"` in `rebar.conf` file. For example:
```
{ct_extra_params, "-boot start_sasl -s myapp -ct_hooks ct_tty_hook"}.
```

Run with `$ rebar ct`.

### erlang.mk

Add flag to `CT_OPTS` variable in your `Makefile`. Fro example: 

```
CT_OPTS = -ct_hooks ct_tty_hook
```

Run with `$ make tests`
