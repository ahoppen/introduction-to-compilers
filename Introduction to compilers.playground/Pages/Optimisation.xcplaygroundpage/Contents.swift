/*:
 # Optimisation
 
 You may have noticed that the IR generated before is often far from optimal. Instead of making the generation of IR more complex, another compiler phase *optimises* the IR. 

 In the real Swift compiler more than 100 different optimisation passes are applied.
 
 We will explore some of the more basic ones in the following.
 
 * callout(Discover):
 Option-click on the different optimisation options below to see what they do.
 */
let optimisationOptions: OptimisationOptions = [.constantExprssionEvaluation,
                                                .constantPropagation,
                                                .deadStoreElimination,
                                                .deadCodeElimination,
                                                .emptyBlockElimination,
                                                .inlineJumpTargets,
                                                .deadBlockElimination
]

let sourceFile: SwiftFile = #fileLiteral(resourceName: "Simple program.swift")

let optimiser = Optimiser(options: optimisationOptions)
/*:
 * callout(Experiment):
 Explore how the optimised code changes when you remove some options in the array above. \
You may notice that many options only produce good results when combined with other options like `.constantExprssionEvaluation` and `.constantPropagation`.
 
 After being optimised, the IR is converted into machine code that is specific to the architecture on which the code will be executed. This means that different machine code is generated depending on whether you compile your code for iPhone/iPad (which have ARM processors) or Mac (which have Intel processors).

 [❮ Back to IR Generation](IRGeneration)

 [❯ Finish](Finish)
 
 ---
 */
// Setup for the live view
import PlaygroundSupport
PlaygroundPage.current.liveView = OptimisationExplorer(withOptimiser: optimiser, forSourceFile: sourceFile)
