//
//  GameScene.swift
//  FlappyBird4
//
//  Created by Yusuke Murayama on 2020/11/15.
//  Copyright © 2020 Yusuke.Murayama. All rights reserved.
//

import SpriteKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate{

    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    // 再生する音源のインスタンス
    var backmusicPlayer = AVAudioPlayer()
    var itemGetPlayer = AVAudioPlayer()
    
    // 衝突判定カテゴリー 　↓追加
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    var score = 0
    
    var itemScore = 0
    
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    var bestItemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.70, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 各種スプライトを生成する処理をメソッドで分ける
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
        
        // bgm再生
        let bgmUrl = Bundle.main.bundleURL.appendingPathComponent("retroparty.mp3")
        
        do {
            try backmusicPlayer = AVAudioPlayer(contentsOf: bgmUrl)
        } catch {
            print("Error")
        }
        backmusicPlayer.play()
        backmusicPlayer.numberOfLoops = -1
        
        // 効果音
        let itemSoundURL = Bundle.main.bundleURL.appendingPathComponent("itemGet.mp3")
        do {
            // 効果音を鳴らす
            itemGetPlayer = try AVAudioPlayer(contentsOf: itemSoundURL)
            
        } catch {
            print("error")
        }
    }
        
        
    func setupGround() {
        
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールすさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            //テクスチャ作成
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            
            //衝突のカテゴリ設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像１枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール→元の位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            
            
            // スプライトにアニメーションを追加する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall =  SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを追加
        let wallAnimation =  SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの３倍にする
        let slit_length = birdSize.height * 3
        
        //　隙間の位置の上下の振れ幅を鳥のサイズの３倍にする
        let random_y_range = birdSize.height * 3
        
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height  / 2 - random_y_range / 2
        
        // 壁を生成するアクションを追加する
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall =  SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 0~random_y_rangeまでのランダムの値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            
            wall.addChild(under)
            
            // 上の壁を作成
            let upper =  SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁の作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        //鳥の画像を二種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //二種類のテクスチャを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリ設定
        bird.physicsBody?.categoryBitMask = birdCategory    //自身のカテゴリを設定
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory  //衝突した時跳ね返る動作をする相手のカテゴリを設定
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory  //衝突する相手のカテゴリを設定
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 { // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { // --- ここから ---
            restart()
        } // --- ここまで追加 ---
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // ゲームオーバーの時には何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"    // ←追加
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        // bodyAをアイテム、bodyBを鳥
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            //アイテムに衝突した
            print("ItemGet")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            itemGetPlayer.play()
            
            if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
                contact.bodyB.node?.removeFromParent()
            }
            
        } else {
            // 壁か地面に衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        
        backmusicPlayer.currentTime = 0
        backmusicPlayer.play()
        
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
        itemScore = 0
        itemScoreLabelNode.text = "Item Score:\(itemScore)"

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
       

    }
    
    func setupItem() {
        //アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingItemDistance = CGFloat(self.frame.size.width * 2)
        
        //画面外まで移動するアクションを追加
        let moveItem = SKAction.moveBy(x: -movingItemDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        //アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run ({
            // アイテム関連のノードを乗せるノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0)
            
            // 画面のY軸方向の中央値
            let center_y = self.frame.size.height / 2
            // アイテムのY座標を上下にランダムさせるときの最大値
            let random_y_range = self.frame.size.height / 2
            // アイテムのY軸の下限
            let item_lowest_y = UInt32(center_y - itemTexture.size().height / 2 - random_y_range / 2)
            // 1~random-y_rangeのランダム整数
            let random_y = arc4random_uniform( UInt32(random_y_range))
            // アイテムのY座標を決定
            let item_y = CGFloat(item_lowest_y + random_y)
            
            // 画面のX軸方向の中央値
            let center_x = self.frame.size.height / 2
            // アイテムのX座標を上下にランダムさせるときの最大値
            let random_x_range = self.frame.size.height / 2
            // アイテムのX軸の下限
            let item_lowest_x = UInt32(center_x - itemTexture.size().height / 2 - random_x_range / 2)
            // 1~random-X_rangeのランダム整数
            let random_x = arc4random_uniform( UInt32(random_x_range))
            // アイテムのX座標を決定
            let item_x = CGFloat(item_lowest_x + random_x)
            
            //アイテムを生成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: item_x, y: item_y)
            
            // 重力を設定
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))
            // 衝突の時に動かないように設定する
            itemSprite.physicsBody?.isDynamic = false
            
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            // 衝突を判定させる相手のカテゴリを設定
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.addChild(itemSprite)
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        //次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテム作成→待ち→アイテム作成を無限に切り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
    }
    

    
}
