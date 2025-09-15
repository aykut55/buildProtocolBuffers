#include <iostream>
#include <fstream>
#include "person.pb.h"              // senin .proto’dan ürettiğin
#include <google/protobuf/message.h> // Protobuf kütüphanesinden

int main() {
    GOOGLE_PROTOBUF_VERIFY_VERSION;

    // --- Serialize ---
    Person person;
    person.set_name("Aykut Tokatlı");
    person.set_id(42);
    person.set_email("aykut@example.com");

    std::ofstream out("person.bin", std::ios::binary);
    if (!person.SerializeToOstream(&out)) {
        std::cerr << "Failed to write person." << std::endl;
        return -1;
    }
    out.close();

    // --- Deserialize ---
    Person person2;
    std::ifstream in("person.bin", std::ios::binary);
    if (!person2.ParseFromIstream(&in)) {
        std::cerr << "Failed to read person." << std::endl;
        return -1;
    }
    in.close();

    std::cout << "Name : " << person2.name() << "\n"
        << "Id   : " << person2.id() << "\n"
        << "Email: " << person2.email() << std::endl;

    google::protobuf::ShutdownProtobufLibrary();
    return 0;
}

