/*:
 - callout(Xcode issue):
 If you see the error message \
`Playground execution failed: error: Introduction.xcplaygroundpage:11:17: error: use of undeclared type 'SwiftFile'` \
wait for about 30 seconds to let the playground compile auxiliary classes that are needed for the execution in this pages. \
I have filed this bug as [rdar://30999038](rdar://30999038)

 
 # Do you know how compilers work?
 Your Mac by itself cannot understand Swift code, but it can only execute very low-level *assembly* instructions like `add`, `shift` or `branch`. It doesn't know about classes or even `if` statements.

 To make your Swift programs run on your Mac, we need a program that translates Swift into assembly code. This program is called a *compiler*. The compiler is always invoked when you build a program in Xcode or when you see `Compiling` in the status bar of a Playground.

 In the following pages you will have a chance to discover interactively how compilers work and which phases modern compilers go through to compile your program.

 As a high-level overview, consider you have written the following Swift code:
 */
let sourceFile: SwiftFile = #fileLiteral(resourceName: "Simple program.swift")
/*: 
 Then the Swift compiler will *compile* the Swift code into assembly code that may look like this:
 */
do {
    try Compiler.compile(swiftFile: sourceFile)
} catch let error as CompilationError {
    error
}
/*:
 
 * callout(Discover):
 Choose different Swift programs above and see how the assembly code changes.

 
 * note:
 To change the program to compile, double-click on “Simple Program” on top of the page

 [❯ Start with the lexer](Lexer)
 
 ---
 */
