import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0


Item {
    id: holder

    property ListModel model
    property double wRatio : 16/9
    property double hRatio : 9/16

    property bool debug: false
    width: width
    height: height
    Component.onCompleted: {
        if(debug) console.log("MB: " + JSON.stringify(model.get(0)))

        if (model && model.count && model.get(0).type === "video") {
            //console.log("Mediablock")
            //console.log(JSON.stringify(model.get(0).type))
            while (model.count>1) {
                model.remove(model.count-1)
            }
        }
        var count = 0
        if (model && model.count)
            count = model.count
        switch(count){

        case 1:
            placeholder1.width = holder.width
            placeholder1.height = placeholder1.width*hRatio
            placeholder1.visible = true;
            holder.height = placeholder1.height
            break;

        case 2:
            placeholder1.visible = true
            placeholder2.visible = true
            placeholder1.width = (holder.width-Theme.paddingSmall)/2
            placeholder1.height = placeholder1.width
            placeholder2.width = placeholder1.width
            placeholder2.height = placeholder1.width
            placeholder2.x = placeholder1.width + placeholder2.x + Theme.paddingSmall
            holder.height = placeholder1.height
            break;

        case 3:
            placeholder1.visible = true
            placeholder2.visible = true
            placeholder3.visible = true
            placeholder4.visible = false

            placeholder1.width = holder.width - Theme.paddingSmall - Theme.itemSizeLarge;
            placeholder1.height = Theme.itemSizeLarge*2+Theme.paddingSmall
            holder.height = placeholder1.height

            placeholder2.width = Theme.itemSizeLarge;
            placeholder3.height = placeholder3.width = placeholder2.height = placeholder2.width
            placeholder3.x = placeholder2.x = placeholder1.x + placeholder1.width + Theme.paddingSmall;
            placeholder3.y = placeholder2.y + placeholder2.height + Theme.paddingSmall;
            break;

        case 4:
            placeholder1.visible = true
            placeholder2.visible = true
            placeholder3.visible = true
            placeholder4.visible = true

            placeholder1.width = placeholder2.width = placeholder3.width = placeholder4.width =  (holder.width - 3*Theme.paddingSmall)/4
            placeholder1.height = placeholder2.height = placeholder3.height = placeholder4.height = Theme.itemSizeLarge*2+Theme.paddingSmall
            placeholder2.x = 1*(placeholder1.width)+ 1*Theme.paddingSmall
            placeholder3.x = 2*(placeholder1.width)+ 2*Theme.paddingSmall
            placeholder4.x = 3*(placeholder1.width)+ 3*Theme.paddingSmall

            holder.height = placeholder1.height            
            break;

        default:
            holder.height = 0
            placeholder1.visible = placeholder2.visible = placeholder3.visible = placeholder4.visible = false;
        }
    }

    MyMedia {
        id: placeholder1
        width: 2
        height: 1
        opacity: pressed ? 0.6 : 1
        visible: {
            if (model && model.count){
                type = model.get(0).type
                previewURL = model.get(0).preview_url
                mediaURL = model.get(0).url
                url = model.get(0).url
                description = model.get(0).description || ''
                if(debug) console.log( model.get(0).url )
                height = Theme.itemSizeLarge
                return true
            } else {
                height = 0
                return false
            }
        }
    }

    MyMedia {
        id: placeholder2
        width: 2
        height: 1
        opacity: pressed ? 0.6 : 1
        visible: {
            if (model && model.count && model.get(1)){
                type = model.get(1).type
                previewURL = model.get(1).preview_url
                mediaURL = model.get(1).url
                url = model.get(1).url
                description = model.get(1).description || ''
                if(debug) console.log( model.get(1).url )
                height = Theme.itemSizeLarge
                return true
            } else {
                height = 0
                return false
            }
        }
    }

    MyMedia {
        id: placeholder3
        width: 2
        height: 1
        opacity: pressed ? 0.6 : 1
        visible: {
            if (model && model.count && model.get(2)){
                type = model.get(2).type
                previewURL = model.get(2).preview_url
                mediaURL = model.get(2).url
                url = model.get(2).url
                description = model.get(2).description || ''
                height = Theme.itemSizeLarge
                return true
            } else {
                height = 0
                return false
            }
        }
    }

    MyMedia {
        id: placeholder4
        width: 2
        height: 1
        opacity: pressed ? 0.6 : 1
        visible: {
            if (model && model.count && model.get(3)){
                type = model.get(3).type
                previewURL = model.get(3).preview_url
                mediaURL = model.get(3).url
                url = model.get(3).url
                description = model.get(3).description || ''
                height = Theme.itemSizeLarge
                return true
            } else {
                height = 0
                return false
            }
        }
    }
}
