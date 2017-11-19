//
//  MultipeerClient.swift
//  DeckRocket
//
//  Created by JP Simard on 6/14/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

typealias StateChange = (MCSessionState, MCPeerID) -> ()

final class MultipeerClient: NSObject, MCNearbyServiceBrowserDelegate, MCSessionDelegate {

    // MARK: Properties

    var onStateChange: StateChange?
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let browser: MCNearbyServiceBrowser
    private var session: MCSession?

    // MARK: Init

    override init() {
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: "deckrocket")
        super.init()
        browser.delegate = self
        browser.startBrowsingForPeers()
    }

    // MARK: Send

    func send(string: String) {
        guard let session = self.session else { return }

        do {
            let data = string.data(using: .utf8)!
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            DispatchQueue.main.async {
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
                let message = "Connection error: \(error.localizedDescription)"
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                rootVC.present(alertController)
            }
        }
    }

    // MARK: MCNearbyServiceBrowserDelegate

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String:String]?)
    {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        self.session = session
        session.delegate = self

        browser.stopBrowsingForPeers()
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }

    // MARK: MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .notConnected {
            browser.startBrowsingForPeers()
        }

        onStateChange?(state, peerID)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try! data.write(to: documentsURL.appendingPathComponent("slides"), options: [])

        guard let slides = Slide.slidesfromData(data)?.flatMap({ $0 }) else {
            print("invalid slides data")
            return
        }

        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController as? ViewController else { return }
            rootVC.slides = slides
        }
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID)
    {
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress)
    {
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?)
    {
    }
}
