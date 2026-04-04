#ifndef SHARARA_BLUETOOTH_HANDLER_H_
#define SHARARA_BLUETOOTH_HANDLER_H_

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Networking.Sockets.h>
#include <winrt/Windows.Storage.Streams.h>

#include <memory>

namespace sharara_bluetooth {

    class ShararaBluetoothHandler {
    public:
        explicit ShararaBluetoothHandler(flutter::PluginRegistrarWindows* registrar);
        virtual ~ShararaBluetoothHandler();

        void call(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    private:
        flutter::PluginRegistrarWindows* registrar_;

        winrt::Windows::Networking::Sockets::StreamSocket socket_{nullptr};
        winrt::Windows::Storage::Streams::DataWriter writer_{nullptr};
        winrt::Windows::Devices::Enumeration::DeviceWatcher device_watcher_{nullptr};

        winrt::fire_and_forget HandleStartDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        winrt::fire_and_forget HandleConnect(const flutter::EncodableMap& args, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        winrt::fire_and_forget HandleWriteToDevice(const flutter::EncodableMap& args, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        void StopDiscovery();
        void Disconnect();
    };

} // namespace sharara_bluetooth

#endif