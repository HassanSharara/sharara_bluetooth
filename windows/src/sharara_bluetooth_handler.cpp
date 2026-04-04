#include "sharara_bluetooth_handler.h"
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Devices.Bluetooth.Rfcomm.h>

using namespace winrt;
using namespace Windows::Devices::Bluetooth;
using namespace Windows::Devices::Enumeration;
using namespace Windows::Networking::Sockets;
using namespace Windows::Storage::Streams;

namespace sharara_bluetooth {

    ShararaBluetoothHandler::ShararaBluetoothHandler(flutter::PluginRegistrarWindows* registrar)
            : registrar_(registrar) {}

    ShararaBluetoothHandler::~ShararaBluetoothHandler() {
        Disconnect();
        StopDiscovery();
    }

    void ShararaBluetoothHandler::call(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

        const std::string& method = method_call.method_name();

        try {
            if (method == "startDiscovery") {
                HandleStartDiscovery(std::move(result));
            } else if (method == "cancelDiscovery") {
                StopDiscovery();
                result->Success(flutter::EncodableValue(nullptr));
            } else if (method == "connect") {
                const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
                if (args) HandleConnect(*args, std::move(result));
                else result->Error("ARG_ERR", "Invalid arguments");
            } else if (method == "writeToDevice") {
                const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
                if (args) HandleWriteToDevice(*args, std::move(result));
                else result->Error("ARG_ERR", "Invalid arguments");
            } else if (method == "disconnect") {
                Disconnect();
                result->Success(flutter::EncodableValue(true));
            } else {
                result->NotImplemented();
            }
        } catch (...) {
            result->Error("UNEXPECTED_ERROR", "A native crash was prevented.");
        }
    }

    fire_and_forget ShararaBluetoothHandler::HandleStartDiscovery(
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        try {
            StopDiscovery();
            // This line fails if Bluetooth hardware is missing
            auto selector = BluetoothDevice::GetDeviceSelector();
            device_watcher_ = DeviceInformation::CreateWatcher(selector);

            if (device_watcher_) {
                device_watcher_.Start();
                result->Success(flutter::EncodableValue("Discovery started"));
            } else {
                result->Error("NO_ADAPTER", "No Bluetooth adapter found.");
            }
        } catch (hresult_error const& ex) {
            result->Error("WINRT_ERR", to_string(ex.message()));
        }
        co_return;
    }

    fire_and_forget ShararaBluetoothHandler::HandleConnect(
            const flutter::EncodableMap& args,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        try {
            auto it = args.find(flutter::EncodableValue("address"));
            if (it == args.end()) { result->Error("ADDR_MISSING", "Address required"); co_return; }

            std::string address = std::get<std::string>(it->second);
            auto device = co_await BluetoothDevice::FromIdAsync(to_hstring(address));

            if (!device) { result->Error("DEV_NOT_FOUND", "Device not found"); co_return; }

            auto services = co_await device.GetRfcommServicesAsync();
            if (services.Services().Size() > 0) {
                socket_ = StreamSocket();
                auto service = services.Services().GetAt(0);
                co_await socket_.ConnectAsync(service.ConnectionHostName(), service.ConnectionServiceName());
                writer_ = DataWriter(socket_.OutputStream());
                result->Success(flutter::EncodableValue(true));
            } else {
                result->Error("NO_RFCOMM", "Device has no SPP/RFCOMM service");
            }
        } catch (hresult_error const& ex) {
            result->Error(std::to_string(ex.code()), to_string(ex.message()));
        }
    }

    fire_and_forget ShararaBluetoothHandler::HandleWriteToDevice(
            const flutter::EncodableMap& args,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (!writer_) { result->Error("NOT_CONNECTED", "No active connection"); co_return; }
        try {
            auto it = args.find(flutter::EncodableValue("data"));
            auto data = std::get<std::vector<uint8_t>>(it->second);
            writer_.WriteBytes(data);
            co_await writer_.StoreAsync();
            result->Success(flutter::EncodableValue(true));
        } catch (hresult_error const& ex) {
            result->Error("WRITE_FAIL", to_string(ex.message()));
        }
    }

    void ShararaBluetoothHandler::StopDiscovery() {
        if (device_watcher_) {
            try {
                if (device_watcher_.Status() == DeviceWatcherStatus::Started) device_watcher_.Stop();
            } catch (...) {}
            device_watcher_ = nullptr;
        }
    }

    void ShararaBluetoothHandler::Disconnect() {
        if (writer_) { try { writer_.DetachStream(); } catch(...) {} writer_ = nullptr; }
        if (socket_) { try { socket_.Close(); } catch(...) {} socket_ = nullptr; }
    }

} // namespace sharara_bluetooth