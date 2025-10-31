document.addEventListener('DOMContentLoaded', function () {
    const container = document.querySelector('.container');

    window.addEventListener('message', function (event) {
        if (event.data.action === 'open') {
            container.style.display = 'block';
        } else if (event.data.action === 'close') {
            container.style.display = 'none';
        }
    });

    document.getElementById('purchase').addEventListener('click', function () {
        fetch(`https://Trunk_Monkeys2/purchase`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(resp => console.log(resp));
        container.style.display = 'none';
    });

    document.getElementById('close').addEventListener('click', function () {
        fetch(`https://Trunk_Monkeys2/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(resp => console.log(resp));
        container.style.display = 'none';
    });
});
