import 'dart:async';
import 'dart:io';
import 'dart:convert'; // For jsonEncode if inspecting complex results, though not strictly needed for empty payloads

import 'package:mcp_client/mcp_client.dart';

/// Example MCP client application that connects to an SSE-based MCP server,
/// lists all available tools, calls each tool, prints the results, and then exits.
void main() async {
  print('[ToolTester] Starting New SSE Tool Tester Example...');

  // Client configuration
  const clientName = 'New SSE Tool Tester Example';
  const clientVersion = '1.0.0';

  // IMPORTANT: Configure this URI to point to your SSE MCP server.
  final sseServerUri = Uri.parse('http://127.0.0.1:8052/sse');
  print('[ToolTester] Target SSE Server URI: $sseServerUri (NEEDS CONFIGURATION BY USER)');

  // Create an MCP client instance
  final client = McpClient.createClient(
    name: clientName,
    version: clientVersion,
    capabilities: ClientCapabilities( // Basic capabilities
      roots: false,
      rootsListChanged: false,
      sampling: false,
    ),
  );

  ClientTransport? transport; // Declare transport here to be accessible in finally

  try {
    print('[ToolTester] Creating SseTransport...');
    transport = await McpClient.createSseTransport(
      serverUrl: sseServerUri.toString(),
    );
    print('[ToolTester] SseTransport created.');

    // Completer to wait for connection success or failure
    final connectionCompleter = Completer<ServerInfo>();

    // Register essential event handlers
    client.onConnect.listen((ServerInfo serverInfo) {
      print('[ToolTester] Connected to server: ${serverInfo.name} v${serverInfo.version}');
      if (!connectionCompleter.isCompleted) {
        connectionCompleter.complete(serverInfo);
      }
    });

    client.onError.listen((McpError error) {
      print('[ToolTester] MCP Error: ${error.message}');
      // Removed access to error.data as it's not defined for McpError.
      // error.message is already printed.
      if (!connectionCompleter.isCompleted) {
        connectionCompleter.completeError(error);
      }
    });

    client.onDisconnect.listen((DisconnectReason reason) {
      print('[ToolTester] Disconnected. Reason: ${reason.toString()}');
      if (!connectionCompleter.isCompleted) {
        // If disconnect happens before onConnect, it's an error for the connection attempt.
        connectionCompleter.completeError(StateError('Disconnected before connection established. Reason: $reason'));
      }
    });

    print('[ToolTester] Attempting to connect to server...');
    await client.connect(transport);

    // Wait for connection to be established or fail
    ServerInfo serverInfo;
    try {
      serverInfo = await connectionCompleter.future.timeout(const Duration(seconds: 10));
      print('[ToolTester] Connection successful. Server: ${serverInfo.name}');
    } catch (e) {
      print('[ToolTester] Connection failed or timed out: $e');
      await _cleanupAndExit(client, 1);
      return;
    }

    // 2. List Tools
    List<Tool> tools;
    try {
      print('[ToolTester] Fetching tool list...');
      tools = await client.listTools();
      if (tools.isEmpty) {
        print('[ToolTester] No tools available from the server.');
      } else {
        print('[ToolTester] Found ${tools.length} tools:');
        for (final tool in tools) {
          print('  - ${tool.name}: ${tool.description}');
        }
      }
    } catch (e) {
      print('[ToolTester] Error listing tools: $e');
      // Decide if to exit or continue if possible
      await _cleanupAndExit(client, 1);
      return;
    }

    // 3. Call Each Tool
    if (tools.isNotEmpty) {
      print('\n[ToolTester] Calling each available tool...');
      for (final tool in tools) {
        print("\n[ToolTester] Calling tool '${tool.name}'...");
        try {
          // Using an empty map as payload for simplicity.
          // For tools with required inputs, this might result in an error from the tool,
          // which is acceptable for this example's purpose of demonstrating callTool.
          final Map<String, dynamic> payload = {};
          print("[ToolTester]   - Payload: ${jsonEncode(payload)}");

          final result = await client.callTool(tool.name, payload);

          if (result.isError == true) {
            final errorContent = result.content.isNotEmpty && result.content.first is TextContent
                ? (result.content.first as TextContent).text
                : (result.content.isNotEmpty ? "Non-TextContent error: ${result.content.first.runtimeType}" : "Unknown error structure or empty error content");
            print("[ToolTester]   - Result for '${tool.name}': ERROR - $errorContent");
          } else {
            final responseText = result.content.isNotEmpty && result.content.first is TextContent
                ? (result.content.first as TextContent).text
                : (result.content.isNotEmpty ? "Non-TextContent response: ${result.content.first.runtimeType}" : "Empty or non-standard response");
            print("[ToolTester]   - Result for '${tool.name}': SUCCESS - Response: $responseText");
            // Optionally, print full content if more complex:
            // if (result.content.isNotEmpty) {
            //   for (var contentItem in result.content) {
            //     print("[ToolTester]     - Content type: ${contentItem.runtimeType}, Text: ${contentItem is TextContent ? contentItem.text : 'N/A'}");
            //   }
            // }
          }
        } catch (e, s) {
          print("[ToolTester]   - Exception calling tool '${tool.name}': $e");
          print("[ToolTester]     StackTrace: $s");
        }
      }
    }

    print('\n[ToolTester] All operations completed.');

  } catch (e, s) {
    print('[ToolTester] An unexpected error occurred: $e');
    print('[ToolTester] StackTrace: $s');
    await _cleanupAndExit(client, 1, isConnected: client.isConnected);
    return;
  }

  // 5. Clean Exit
  await _cleanupAndExit(client, 0, isConnected: client.isConnected);
}

Future<void> _cleanupAndExit(Client client, int exitCode, {bool isConnected = false}) async {
  print('[ToolTester] Initiating cleanup and exit (code: $exitCode)...');
  if (isConnected) { // Check if client thinks it's connected
    try {
      print('[ToolTester] Disconnecting client...');
      client.disconnect(); // disconnect is synchronous
      print('[ToolTester] Client disconnected.');
    } catch (e) {
      print('[ToolTester] Error during disconnect: $e');
    }
  } else {
    print('[ToolTester] Client was not connected or already disconnected. Skipping explicit disconnect call.');
  }
  print('[ToolTester] Exiting application.');
  exit(exitCode);
}