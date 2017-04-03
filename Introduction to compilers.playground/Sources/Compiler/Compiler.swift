/// Driver for the compiler phases implemented in this playground that invokes
/// the different compiler phases described on the different playground pages
public class Compiler {
    /// Compile the given Swift file to Intermediate Representation without optimising it
    ///
    /// - Parameter file: The Swift file to compile
    /// - Returns: The compiled IR
    /// - Throws: A compilation error if compilation failed
    public static func compile(swiftFile file: SwiftFile) throws -> IR {
        let parser = Parser()
        let ast = try parser.parse(sourceFile: file)

        let typechecker = Typechecker()
        try typechecker.typecheck(node: ast)

        return IRGen.generateIR(forAST: ast)
    }
}
