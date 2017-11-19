//
//  MultipeerClient.swift
//  DeckRocket
//
//  Created by JP Simard on 6/13/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

typealias StateChange = (MCSessionState) -> Void
private typealias KVOContext = UInt8
private var progressContext = KVOContext()
private var lastDisplayTime = NSDate()

final class MultipeerClient: NSObject, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {

    // MARK: Properties

    var onStateChange: StateChange?
    private let localPeerID = MCPeerID(displayName: Host.current().localizedName!)
    private let advertiser: MCNearbyServiceAdvertiser
    private var session: MCSession?
    private var pdfProgress: Progress?

    // MARK: Lifecycle

    override init() {
        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: "deckrocket")
        super.init()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    // MARK: Send File

    func sendSlides(_ scriptingSlides: [DecksetSlide]) {
        guard let session = self.session, let peer = session.connectedPeers.first else {
            HUDView.show("Error!\nRemote not connected")
            return
        }

        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                HUDView.showWithActivity("Exporting slides...")
            }

            let slidesData = NSKeyedArchiver.archivedData(withRootObject: scriptingSlides.map {
                Slide(pdfData: $0.pdfData, notes: $0.notes)!.dictionaryRepresentation!
            })

            DispatchQueue.main.async {
                HUDView.showWithActivity("Sending slides...")
            }

            do {
                try session.send(slidesData, toPeers: [peer], with: .reliable)
                DispatchQueue.main.async {
                    HUDView.show("Success!")
                }
            } catch {
                DispatchQueue.main.async {
                    HUDView.show("Error!\n\(error)")
                }
            }
        }
    }

    // MARK: MCNearbyServiceAdvertiserDelegate

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        self.session = session
        session.delegate = self

        advertiser.stopAdvertisingPeer()
        invitationHandler(true, session)
    }

    // MARK: MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .notConnected {
            advertiser.startAdvertisingPeer()
        }

        onStateChange?(state)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let string = String(data: data, encoding: .utf8), let slideIndex = Int(string) else {
            print("invalid data received from client")
            return
        }

        guard let decksetApp = DecksetApp(), let document = decksetApp.documents.first else {
            print("no document in Deckset application")
            return
        }

        document.setSlideIndex(slideIndex)
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
