/*:
 # What have we learned?
 
 Modern compilers go through multiple independent phases to reduce the complexity of compilation:
 
 - The **lexer** transforms the stream of characters in the source code into categorised tokens
 - The **parser** organises the tokens in an abstract syntax tree (AST) to understand the source code's semantics
 - The **type checker** will then verify that there are no type system violations in the AST
 - **Code generation** flattens the AST into a compiler-internal intermediate representation (IR) that consists of multiple basic blocks and uses `branch` and `jump` to transfer control flow
 - The **optimiser** optimises the IR to generate more efficient code and remove artifacts that resulted from previous compilation steps
 - Lastly, the IR is translated into **machine code** that depends on the architecture for which the program is being compiled
 
 * callout(Discover):
 The Swift compiler is open source. Have a look at how the `if` statement gets parsed [there](https://github.com/apple/swift/blob/f23ec8855d8f633d3bfb1b7c79ed0a0bf42dd57d/lib/Parse/ParseStmt.cpp#L1345).

 [❮ Back to Optimisation](Optimisation)

 ---
 */
