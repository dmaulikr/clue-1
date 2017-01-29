//
//  PLayer.swift
//  ClueFlex
//
//  Created by Gina Bolognesi on 2016-07-12.
//  Copyright © 2016 Gina Bolognesi. All rights reserved.
//

import SpriteKit

class Player: NSObject{
    
    var hand: [Card]
    var position: Position?
    var character: Card
    
    var sprite : SKSpriteNode?

    var suspect: Bool
    
    var counter: Int
    
    init(c:Card)
    {
        character = c;
        hand = [Card]()
        
        suspect = true
        counter = 0
    }
    
    
    func reply(_ t: Trio, p:Player) -> Card?
    {
        
        return nil
    }
    
    func play()
    {
        let roll = rollDie()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.move(num: roll)
            if(self.isInRoom())
            {
                Game.getGame().moveToRoomView()
                self.chooseSuspectOrAccuse()
                let question = self.selectPersonWeapon()
                let answer = self.ask(question)
                
                //nil only if waiting for human input
                if(answer != nil)
                {
                    self.takeNotes(answer!, question: question)
                    Game.getGame().moveToBoardView()
                    self.passTurn()
                }
                
            }else{
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double)(roll)) {
                    self.passTurn()
                }
            }
        }
        
    }
    
    func rollDie() -> Int
    {
        let roll = Int(arc4random_uniform(UInt32(6))+1);
        if(!(self is HumanPlayer))
        {
            self.playRollAnimation(die: roll);
        }
        return roll
    }
    
    func playRollAnimation(die: Int)
    {
        let root = Game.getGame().boardScene.childNode(withName: "UICONTROLS")!
        let textDisplay = root.childNode(withName: "TextDisplay") as! SKLabelNode
        
        textDisplay.text = self.character.name + "'s turn!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            root.childNode(withName: "Die"+die.description)?.run(SKAction.unhide())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Game.getGame().boardScene.rollDie(roll: die); // return random int if not provided with one
            textDisplay.text = self.character.name + " rolled " +  die.description;
            
        }
        
    }

    
    func move(num: Int)
    {
        
    }
    
    /*
    //animation - move sprite node in 2 moves x and y, largest first, set new position
    func moveToken(newPos: Position)
    {
        let root = Game.getGame().boardScene.childNode(withName: "UICONTROLS")!
        root.childNode(withName: "Die")?.run(SKAction.hide())
        
        if(sprite == nil)
        {
            sprite = (Game.getGame().boardScene.childNode(withName: "BoardBackground")!.childNode(withName: character.name) as! SKSpriteNode)
        }
        
        
        let newX = newPos.sprite.position.x
        let newY = newPos.sprite.position.y
        
        let oldX = position!.sprite.position.x
        let oldY = position!.sprite.position.y
        
        if (abs(oldX-newX) > abs(oldY - newY))
        {
            //sprite?.run(SKAction.group([SKAction.move(to: CGPoint(x: newX, y: oldY), duration: 1.5), SKAction.move(to: CGPoint(x: newX, y: newY), duration: 1.5)]))
            
            sprite?.run(SKAction.move(to: CGPoint(x: newX, y: oldY), duration: 1.0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.sprite?.run(SKAction.move(to: CGPoint(x: newX, y: newY), duration: 1.0))
            }

        }else{
            //sprite?.run(SKAction.group([SKAction.move(to: CGPoint(x: oldX, y: newY), duration: 1.5), SKAction.move(to: CGPoint(x: newX, y: newY), duration: 1.5)]))
            sprite?.run(SKAction.move(to: CGPoint(x: oldX, y: newY), duration: 1.0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.sprite?.run(SKAction.move(to: CGPoint(x: newX, y: newY), duration: 1.0))
            }
        }
        
        position?.isOccupied = false;
        position = newPos
        newPos.isOccupied = true;
        
    }
    */
    
    //animation - move through path
    func moveToken(newPos: Position, p: [Position]?)
    {
        let root = Game.getGame().boardScene.childNode(withName: "UICONTROLS")!
        root.childNode(withName: "Die")?.run(SKAction.hide())
        
        position?.isOccupied = false;
        position = newPos
        newPos.isOccupied = true;
        
        if(sprite == nil)
        {
            sprite = (Game.getGame().boardScene.childNode(withName: "BoardBackground")!.childNode(withName: character.name) as! SKSpriteNode)
        }
        
        var path = p;
        
        if(path == nil)
        {
            path = self.position?.shortestPathTo(newPos)
        }
        
        var i = 0.0;
        while(!(path?.isEmpty)!){
            let top = path?.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + i*1) {
                self.sprite?.run(SKAction.move(to: top!.sprite.position, duration: 1.0))
            }
            i += 1;
        }
        
    }

    
    func isInRoom() -> Bool
    {
        return (position?.isRoom)!;
        
    }
    
    func chooseSuspectOrAccuse()
    {
        
    }
    
    func selectPersonWeapon() -> Trio
    {
        return Trio(person: Game.getGame().players[0].character , weapon: (Game.getGame().roomScene?.weapons![0])!, location: self.position!.room!)
    }
    
    //returns nil if no one has anything
    func ask(_ question: Trio) -> Answer?
    {
        let players = Game.getGame().players
        let me = players.index(of: self)
        let numPlayers = players.count
        counter = (me! + 1) % numPlayers;
        
        var answer: Card?
        var responder: Player?
        
        while(answer == nil && counter != me)
        {
            if(players[counter] is HumanPlayer)
            {
                players[counter].reply(question, p: self) // changes state
                return nil
            }
            answer = players[counter].reply(question, p: self)
            
            if(answer != nil)
            {
                responder = players[counter]
            }
            
            counter = counter + 1
            counter = counter % numPlayers
        }

        return Answer(card: answer, person: responder)
    }
    
    
    func resumeAsk(_ question: Trio, humanAns: Card?)
    {
        let players = Game.getGame().players
        let me = players.index(of: self)
        let numPlayers = players.count
        
        var answer = humanAns
        var result: Answer
        if(answer != nil)
        {
            result = Answer(card: answer, person: Game.getGame().humanPlayer)
        }else{
            
            var responder: Player?
            
            while(answer == nil && counter != me)
            {
                
                answer = players[counter].reply(question, p:self)
                
                if(answer != nil)
                {
                    responder = players[counter]
                }
                
                counter = counter + 1
                counter = counter % numPlayers
            }
            
            result = Answer(card: answer, person: responder)
        }
        
        takeNotes(result, question: question)
        Game.getGame().moveToBoardView()
        passTurn()
    }
    
    
    
    func takeNotes(_ answer: Answer, question: Trio)
    {
        
    }
    
    
    func passTurn()
    {
        Game.getGame().currentPlayer = Game.getGame().players[(Game.getGame().players.index(of: self)!+1) % Game.getGame().players.count]
        Game.getGame().updatePList()
        
        let root = Game.getGame().boardScene.childNode(withName: "UICONTROLS")!
        let textDisplay = root.childNode(withName: "TextDisplay") as! SKLabelNode
        
        if(Game.getGame().currentPlayer is HumanPlayer)
        {
            Game.getGame().state = State.startOfTurn
            textDisplay.text = "Your turn!"
            
        }else{
            Game.getGame().state = State.waitingForTurn
            
            Game.getGame().currentPlayer.play()
            textDisplay.text = Game.getGame().currentPlayer.character.name + "'s turn!"
        }
        (Game.getGame().boardScene.childNode(withName: "CurrentPlayer") as! SKSpriteNode).texture = SKTexture(imageNamed: (Game.getGame().currentPlayer.character.imageName))
    }
    
    
    
}

func ==(lhs: Player, rhs: Player) -> Bool {
    return lhs.sprite == rhs.sprite && lhs.hand == rhs.hand && lhs.position == rhs.position && rhs.character == rhs.character
}

