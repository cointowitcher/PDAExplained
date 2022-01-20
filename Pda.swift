import Foundation

// Here available states, which will be used on the stack, are declared
enum PdaState: CustomStringConvertible, Hashable {
    var description: String {
        switch self {
        case .A: return "<A>"
        case .D: return "<D>"
        case .B: return "<B>"
        case .E: return "<E>"
        case .C: return "<C>"
        }
    }
    
    case A
    case D
    case B
    case E
    case C
}

// All the characters that can be used for parsing
enum Input: String, Hashable {
    case a
    case b
    case c
    case minus = "-"
    case asterisk = "*"
    case leftBracket = "("
    case rightBracket = ")"
    case dollar = "$"
}

enum StateSymbol: CustomStringConvertible {
    case terminal(Input)
    case state(PdaState)
    case empty
    
    var description: String {
        switch self {
        case let .terminal(s): return s.rawValue
        case let .state(state): return "\(state)"
        case .empty: return ""
        }
    }
}

// The structure that combines nonterminal states and input characters
struct PdaStateInput: Hashable {
    var ps: PdaState
    var inp: Input
    init(_ ps: PdaState, _ inp: Input) {
        self.ps = ps
        self.inp = inp
    }
}

// LL(1) Parsing/Jump Table. It basically defines the way one state transforms to another based on the last state on the stack and current input
let mTable: [PdaStateInput: [StateSymbol]] = [
    .init(.A, .a): [.state(.B), .state(.D)],
    .init(.A, .b): [.state(.B), .state(.D)],
    .init(.A, .c): [.state(.B), .state(.D)],
    .init(.B, .a): [.state(.C), .state(.E)],
    .init(.B, .b): [.state(.C), .state(.E)],
    .init(.B, .c): [.state(.C), .state(.E)],
    .init(.C, .a): [.terminal(.a)],
    .init(.C, .b): [.terminal(.b)],
    .init(.C, .c): [.terminal(.c)],
    .init(.D, .minus): [.terminal(.minus), .state(.B), .state(.D)],
    .init(.E, .minus): [.empty],
    .init(.E, .asterisk): [.terminal(.asterisk), .state(.C), .state(.E)],
    .init(.A, .leftBracket): [.state(.B), .state(.D)],
    .init(.B, .leftBracket): [.state(.C), .state(.E)],
    .init(.C, .leftBracket): [.terminal(.leftBracket), .state(.A), .terminal(.rightBracket)],
    .init(.D, .rightBracket): [.empty],
    .init(.E, .rightBracket): [.empty],
    .init(.D, .dollar): [.empty],
    .init(.E, .dollar): [.empty]
]

struct StringError: Error, LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

public extension String {
    // This extension's function allows the string to be of a certain length. This functions serves aesthetic purposes.
    func paddedToWidth(_ width: Int) -> String {
        let length = self.count
        guard length < width else {
            return self
        }

        let spaces = Array<Character>.init(repeating: " ", count: width - length)
        return self + spaces
    }
    
    // It does what it says. If we have a string "ABC" and use this function, the string turns into "BC"
    func removeFirstSymbol() -> String {
        return String(self[self.index(self.startIndex, offsetBy: 1)...])
    }
}

// The main class that is the center of the focus in the current code
class Pda {
    private var stack = [StateSymbol]()
    private var currentString: String
    
    private func translate(_ state: PdaState) throws -> [StateSymbol] {
        // Take the first symbol from the current string and get a new state based on the Parsing/Jump Table. If there's no combination of the state and input in the parsing/jump table, then the error is thrown
        guard let input = Input(rawValue: String(currentString.first!)),
              let symbols = mTable[.init(state, input)] else {
                  throw StringError(message: "No match \(state) to \(currentString.first!)")
              }
        return symbols
    }
    
    init(_ string: String) {
        // Initializes the class. The current string is going to change as the program parses more symbols.
        self.currentString = string + "$"
    }
    
    func analyze() throws {
        stack.append(.terminal(.dollar))
        // Add beginning state
        stack.append(.state(.A))
        log()
        // Start the recursive algorithm of parsing the string
        try recursive()
    }
        
    private func recursive() throws {
        // If the string is empty or there are no elements on the stack, it means that string has been parsed
        guard !currentString.isEmpty, let popped = stack.popLast() else { return }
        switch popped {
        case let .state(state):
            // Using last state obtained from the stack, get the new state(s) and append them at the end of the stack.
            let symbols: [StateSymbol] = (try translate(state)).reversed()
            stack.append(contentsOf: symbols)
            log()
        case let .terminal(terminal):
            // If our stack contains some terminal symbol, but that terminal symbol doesn't match the current string symbol that we are parsing. Then, it means that there are inconsistencies in the string and proper actions have to be done(in this case, just shutting down the program)
            guard Input(rawValue: String(currentString.first!))! == terminal else { throw StringError(message: "Should be \(terminal) got \(currentString.first!)") }
            // If this line of code is executed, it means that the first symbol of the current string has been parsed. Thus, it should be removed
            currentString = currentString.removeFirstSymbol()
            log()
        case .empty: break
        }
        // Continue until there are no symbols left, or the stack is empty
        try recursive()
    }
    
    private func log() {
        // Print into the console current state of the app
        print("\("\(stack.reduce(into: "") { $0 += "\($1)" })".paddedToWidth(20)) \t \(currentString)")
    }
}

// Take input from the console and run the parser
if let input = readLine() {
    let pda = Pda(input)
    do {
        try pda.analyze()
    } catch {
        print("ERROR: " + error.localizedDescription)
    }
} else {
    print("Error")
}

