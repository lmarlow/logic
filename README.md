# Logic [![Build Status](https://travis-ci.org/lmarlow/logic.svg)](https://travis-ci.org/lmarlow/logic)

Logic gates, circuits inspired by Charles Petzold's CODE and the nand2tetris.org course.

    use Logic.HDL
    defchip Xor do
      use Logic.HDL
      in [:in1, :in2]
      out [:out]
      parts Or: [a: :in1, b: :in2, out: :or_out],
            Nand: [a: :in1, b: :in2, out: :nand_out],
            And: [a: :or_out, b: :nand_out, out: out]
    end
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add logic to your list of dependencies in `mix.exs`:

        def deps do
          [{:logic, "~> 0.0.1"}]
        end

  2. Ensure logic is started before your application:

        def application do
          [applications: [:logic]]
        end

